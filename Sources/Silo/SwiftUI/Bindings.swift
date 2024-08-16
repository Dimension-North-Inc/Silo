//
//  Bindings.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-11-07.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import SwiftUI

@_exported import CasePaths

/// A property wrapper used to mark state properties as accessible via SwiftUI bindings,
///
/// Mark state properties you wish to mutate via SwiftUI bindings with the `@Bound`
/// property wrapper:
///
/// ```swift
/// struct User: Reducer {
///     struct State: States {
///         // accessible as `@Binding`
///         @Bound var name: String
///         @Bound var age:  Int
///
///         // not accessible as `@Binding`
///         var isAuthenticated: Bool
///     }
/// ```
///
/// Next, declare your `Action` type as conforming to `BindingActions`, so that
/// binding updates can be interpreted by your reducer.
/// `BindingActions` replaces multiple, per-property update-style actions with a single
/// action that transports SwiftUI binding updates:
///
///```swift
///     // conform `Action` to `BindingActions`
///     enum Action: BindingActions {
///         case authenticate
///
///         // action used to contain binding update actions
///         case binding(BindingAction<State>)
///     }
///```
///
/// Finally,  ensure your reducer body incorprates a `ReduceBindings` in its implementation.
/// `ReduceBindings` interprets and reduces `binding(BindingAction<State>)` actions:
///
/// ```swift
///     var body: some Reducer<State, Action> {
///         // reduce bindings...
///         ReduceBindings()
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
///     @Observable var user: Store<User>
///     ...
///
///     var body: some View {
///         Form {
///             TextField("Username", value: user.$name
///             ...
/// ```
///
@propertyWrapper
public struct Bound<Value> {
    public var wrappedValue: Value
    
    public var projectedValue: Self {
        get { self }
        set { self = newValue }
    }
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}

extension Bound: Codable where Value: Codable {
    public init(from decoder: Decoder) throws {
        self.init(wrappedValue: try Value.init(from: decoder))
    }
    public func encode(to encoder: Encoder) throws {
        try self.wrappedValue.encode(to: encoder)
    }
}

extension Bound: Sendable where Value: Sendable {}
extension Bound: Equatable where Value: Equatable {}

/// An action representing the update of bound state.
///
/// When adding a `ReduceBindings` to your custom reducer body, actions are
/// reported back to you in the reducers `shouldUpdate` closure.
///
public struct BindingAction<State: States> {
    /// the action's aassociated keypath
    public let keyPath: PartialKeyPath<State>
    /// the action's associated value
    public let value: Any
    
    var update: @Sendable (inout State) -> Void
}


/// An Action type used to represent actions that wrap `BindingAction`s
///
/// If reducer `State` contains properties marked `@Bound`, then
/// the reducer's associated `Action` type should conform to `BindingActions` -
/// a specialization of the `Actions` protocol:
///
///```swift
/// struct User: Reducer {
///     struct State: States {
///         // accessible as `@Binding`
///         @Bound var name: String
///         @Bound var age:  Int
///
///         // not accessible as `@Binding`
///         var isAuthenticated: Bool
///     }
///
///     // conform `Action` to `BindingActions`
///     enum Action: BindingActions {
///         case authenticate
///
///         // action used to contain binding update actions
///         case binding(BindingAction<State>)
///     }
///
///     // ...
/// ```
///
/// The protocol's only requirement is that  a conforming `Action` enumeration
/// contains a `case binding(BindingAction<State>)` used to pass
/// binding values into the reducer.
///
public protocol BindingActions: Actions {
    /// The root state type that contains bindable fields.
    associatedtype State: States
    
    /// Embeds a binding action in this action type.
    ///
    /// - Returns: A binding action.
    static func binding(_ action: BindingAction<State>) -> Self
    
    
    /// Extracts a binding action from this action type.
    var binding: BindingAction<State>? { get }
}

extension BindingActions {
    public var binding: BindingAction<State>? {
        AnyCasePath(unsafe: { .binding($0) }).extract(from: self)
    }
}

/// A `Reducer` that reduces `BindableAction`s actions onto state.
///
/// When creating a custom reducer with state properties annotated  using the  `Bindable`
/// property wrapper, add a `ReduceBindings` to its implementation in order to receive and reduce
/// binding updates:
///
/// ```swift
///     var body: some Reducer<State, Action> {
///         ReduceBindings {
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
/// `ReduceBindings` accepts an optional `shouldUpdate` closure which is called for each action
/// it reduces. The action can be used to identify both substate and value to be updated by the reducer. 
///
public struct ReduceBindings<State: States, Action: BindingActions>: Reducer {
    public func reduce(state: inout State, action: Action) -> Effect<Action>? {
        if let action = action.binding as? BindingAction<State>, shouldUpdate(&state, action) {
            action.update(&state)
        }
        return .none
    }
    
    let shouldUpdate: (inout State, BindingAction<State>) -> Bool
    
    public init(shouldUpdate: @escaping (inout State, BindingAction<State>) -> Bool = { _, _ in true }) {
        self.shouldUpdate = shouldUpdate
    }
}

extension Store where Reducer.Action: BindingActions, Reducer.State == Reducer.Action.State {
    public subscript<T>(dynamicMember keyPath: WritableKeyPath<State, Bound<T>>) -> Binding<T> {
        Binding {
            self.state[keyPath: keyPath].wrappedValue
        } set: {
            value, transaction in
            self.dispatch(
                Reducer.Action.binding(
                    BindingAction(keyPath: keyPath, value: value, update: {
                        state in state[keyPath: keyPath].wrappedValue = value
                    })
                )
            )
        }
    }
}
