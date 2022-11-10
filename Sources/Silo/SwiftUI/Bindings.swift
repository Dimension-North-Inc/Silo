//
//  Bindings.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-11-07.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import SwiftUI

/// A property wrapper used to mark state properties as accessible via SwiftUI bindings.
///
/// Mark state properties you wish to mutate via SwiftUI bindings with the `@BindingState`
/// property wrapper, and ensure your reducer incorprates a `BindingReducer` in its implementation:
///
/// ```swift
/// struct Users: Reducer {
///     struct State: States {
///         // accessible as @Binding
///         @BindingState var name: String
///         @BindingState var age:  Int
///
///         // not accessible as @Binding
///         var isAuthenticated: Bool
///     }
///     enum Action: Actions {
///         case authenticate
///     }
///
///     var body: some Reducer<State, Action> {
///         // reduce bindings...
///         BindingReducer()
///
///         // ...then perform other reducer-specific behavior
///         Reduce {
///             state, action in
///             switch action {
///             case .authenticate:
///                 // ...
///         }
///     }
/// }
/// ```
///
/// Once this is done, create view bindings using the usual `$property` syntax:
///
/// ```swift
///     @Observable var user: Store<Users>
///     ...
///
///     var body: some View {
///         Form {
///             TextField("Username", value: user.$name
///             ...
/// ```
///
@propertyWrapper
public struct BindingState<Value> {
    public var wrappedValue: Value
    
    public var projectedValue: Self {
        get { self }
        set { self = newValue }
    }
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}

extension BindingState: Codable where Value: Codable {
    public init(from decoder: Decoder) throws {
        self.init(wrappedValue: try Value.init(from: decoder))
    }
    public func encode(to encoder: Encoder) throws {
        try self.wrappedValue.encode(to: encoder)
    }
}

extension BindingState: Sendable where Value: Sendable {
}

extension BindingState: Equatable where Value: Equatable {
}

/// An action representing the update of bound state.
///
/// When adding a `BindingReducer` to your custom reducer body, actions are
/// reported back to you in the reiducers `shouldUpdate` closure.
///
public struct BindingAction<State: States>: Actions, @unchecked Sendable {
    /// the action's aassociated keypath
    public let keyPath: PartialKeyPath<State>
    /// the action's associated value
    public let value: Any
    
    var update: @Sendable (inout State) -> Void
}

/// A `Reducer` that reduces `BindingAction<State>` actions onto state.
///
/// When creating a custom reducer with state properties annotated  using the  `BindingState`
/// property wrapper, add a `BindingReducer` to its implementation in order to receive and reduce
/// binding updates:
///
/// ```swift
///     var body: some Reducer<State, Action> {
///         BindingReducer {
///             state, action in
///             switch action.keyPath {
///             case \.$name:       print("will update name: \(action.value)")
///             case \.$isVerified: print("will update isVerified: \(action.value)")
///
///             default:            break
///             }
///
///             // allow the update to proceed
///             return true
///         }
///     }
/// ```
///
/// `BindingReducer` accepts an optional `shouldUpdate` closure which is called for each action
/// it reduces. The action can be used to identify both substate and value to be updated by the reducer. 
///
public struct BindingReducer<State: States, Action: Actions>: Reducer {
    public func reduce(state: inout State, action: Action) -> Effect<Actions>? {
        return .none
    }
    public func reduce(state: inout State, action: any Actions) -> Effect<Actions>? {
        if let action = action as? BindingAction<State>, shouldUpdate(&state, action) {
            action.update(&state)
        }
        return .none
    }
    
    let shouldUpdate: (inout State, BindingAction<State>) -> Bool
    
    public init(shouldUpdate: @escaping (inout State, BindingAction<State>) -> Bool = { _, _ in true }) {
        self.shouldUpdate = shouldUpdate
    }
}

extension Store {
    public subscript<T>(dynamicMember keyPath: WritableKeyPath<State, BindingState<T>>) -> Binding<T> {
        Binding {
            self.state[keyPath: keyPath].wrappedValue
        } set: {
            value, transaction in
            self.dispatch(
                BindingAction(keyPath: keyPath, value: value, update: {
                    state in state[keyPath: keyPath].wrappedValue = value
                })
            )
        }
    }
}
