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
/// property wrapper, and ensure reducer state conforms to the `BindingActions` protocol:
///
/// ```swift
/// struct Users: Reducer {
///     struct State: States {
///         // available as bindings
///         @BindingState var name: String
///         @BindingState var age:  Int
///
///         // not available as bindings
///         var isAuthenticated: Bool
///     }
///
///     struct Action: BindingActions {
///         case binding(BindingValue<State>)
///         ...
///     }
/// ```
/// In SwiftUI code:
///
/// ```swift
///     var body: some View {
///         Form {
///             TextField("Username", value: user.$name
///             ...
/// ```
///
/// Unlike regular `@Binding` values, state isn't directly mutated using the`@BindingState` construction.
/// Instead, your reducer receives `.binding(BindingValues<State>)` actions.
///
/// To process these actions, unwrap the passed binding value, and use it to update state:
///
/// ```swift
///     var body: some Reducer<State, Action> {
///         Reduce { state, action in
///             switch action {
///             case let .binding(binding):
///                 binding.update(&state) // updates state
///                 ...
/// }
/// ```
///
/// See `BindingValues<State>` documentation for additional information on processing bound values.
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

/// A protocol for actions which can apply SwiftUI bindings
///
/// When a reducer wraps certain of its state properties using `@BindingState`,
/// binding updates are sent as actions. BindingActions declares the format of these
/// actions:
///
/// ```swift
///     // Action declaration:
///     enum Action: BindingActions {
///         case binding(BindingValue<State>)
///         // other supported actions
///         ...
///     }
/// ```
/// Receive and apply SwiftUI binding updates inside your reducer body:
///
/// ```swift
///         // in the reducer body:
///         switch action {
///             case let .binding(binding):
///                 // receive and apply a SwiftUI binding update
///                 binding.update(&state)
///             ...
/// ```
public protocol BindingActions<State>: Actions {
    associatedtype State: States
    static func binding(_ value: BindingValue<State>) -> Self
}

/// A  binding value used to update state within a reducer.
///
/// When extracting a `BindingValue` from a `BindingAction` via `case-let`, additional
/// properties of the binding can be checked using a where clause on the case:
///
/// ```swift
/// switch action {
///     case let .binding(binding) where binding.keyPath == \.$firstName:
///         binding.update(&state)
///         // validate firstName value
///         ...
/// ```
/// ...or within the case body:
///
/// ```swift
/// switch action {
/// case let .binding(binding):
///     binding.update(&state)
///
///     switch binding {
///         case \.$firstName:
///         // validate firstName value
///         ...
/// ```
///
public struct BindingValue<State: States>: @unchecked Sendable, Equatable {
    public let keyPath: PartialKeyPath<State>
    public let value: Any
    
    public let update: @Sendable (inout State) -> Void
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.keyPath == rhs.keyPath
    }
    public static func ~=(lhs: PartialKeyPath<State>, rhs: Self) -> Bool {
        lhs == rhs.keyPath
    }
}

extension Store where Action: BindingActions, Action.State == Reduce.State {
    public subscript<T>(dynamicMember keyPath: WritableKeyPath<State, BindingState<T>>) -> Binding<T> {
        Binding {
            self.state[keyPath: keyPath].wrappedValue
        } set: {
            value, transaction in
            self.dispatch(
                Reduce.Action.binding(
                    BindingValue(keyPath: keyPath, value: value) {
                        state in state[keyPath: keyPath].wrappedValue = value
                    }
                )
            )
        }
    }
}
