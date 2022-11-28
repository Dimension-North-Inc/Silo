//
//  Context.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-11-27.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

/// A  context used to share state disjointly among reducers.
///
/// Sharing state between reducers is accomplished using an `InContext` reducer:
///
/// ```swift
///     var body: some Reducer<State, Action> {
///         ReduceChild(\.auth, action: /Action.auth)
///         InContext(key: AuthStateKey.self, value: \.auth) {
///             // ...
///         }
///     }
/// ```
///
/// Accessing shared state within a reducer is accomplished using the @Context`
/// property wrapper:
///
/// ```swift
/// struct UserFeature: Reducer {
///     struct State: States {
///         // ...
///     }
///     enum Action: Actions {
///         // ...
///     }
///     @Context(\.auth) var auth
///
///     // ...
/// }
/// ```
///
///- Note: `ContextValues` is currently a singleton commandeered by a store during
/// action `dispatch`. In future, `ContextValues` should migrate to `StateStorage`
/// so each distinct store hieriarchy manages its own context.
///
/// The `Reducer` protocol should, in turm, be modified to accept a third argument
/// to its `reduce` function - the context in which it is being called.
///
public final class ContextValues {
    private var values: [ObjectIdentifier: Any] = [:]
    
    public subscript<Key: ContextKeys>(key: Key.Type) -> Key.Value {
        get { values[ObjectIdentifier(key)] as? Key.Value ?? Key.defaultValue }
        set { values[ObjectIdentifier(key)] = newValue }
    }
    
    static func push<Key: ContextKeys>(_ key: Key.Type, value: Key.Value) {
        shared.values[ObjectIdentifier(key)] = value
    }
    static func pop<Key: ContextKeys>(_ key: Key.Type) {
        shared.values[ObjectIdentifier(key)] = nil
    }
    
    static let mutex  = Mutex()
    static let shared = ContextValues()
}

public protocol ContextKeys {
    associatedtype Value: Sendable
    static var defaultValue: Value { get }
}

@propertyWrapper
public struct Context<Value: Sendable> {
    private let name: KeyPath<ContextValues, Value>
    public init(_ name: KeyPath<ContextValues, Value>) {
        self.name = name
    }
    
    public var wrappedValue: Value {
        return ContextValues.shared[keyPath: name]
    }
}
