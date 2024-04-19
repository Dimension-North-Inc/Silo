//
//  ReduceChild.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-10-30.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

@_exported import CasePaths

/// A `body` reducer used to reduce `Child` substates identified by keypath.
///
/// Where substate is `nil`, the reducer does not execute.
public struct ReduceChild<State: States, Action: Actions>: SubstateReducer {
    var impl: (inout State, Action) -> Effect<Action>?
    
    /// Initializes the reducer with a keypath from local to child state, and a child `reducer` used to reduce child state.
    /// - Parameters:
    ///   - substate: a keypath from local to child state
    ///   - action: a casepath matching a local action wrapping a child action
    ///   - reducer: a child state reducer
    public init<Child: Reducer>(
        _ substate: WritableKeyPath<State, Child.State>,
        action path: AnyCasePath<Action, Child.Action>,
        @ReducerBuilder<Child.State, Child.Action> reducer: @escaping () -> Child
    ) {
        self.impl = {
            state, action in
            if let action = path.extract(from: action),
               let effect = reducer().reduce(state: &state[keyPath: substate], action: action) {
                
                return rewrap(effect: effect, using: path)
                
            } else {
                return .none
            }
        }
    }
    
    /// Initializes the reducer with a keypath from local to child state, and a child `reducer` used to reduce child state
    /// **if child state is not nil**.
    /// - Parameters:
    ///   - substate: a keypath from local to child state
    ///   - action: a casepath matching a local action wrapping a child action
    ///   - reducer: a child state reducer
    public init<Child: Reducer>(
        _ substate: WritableKeyPath<State, Child.State?>,
        action path: AnyCasePath<Action, Child.Action>,
        @ReducerBuilder<Child.State, Child.Action> reducer: @escaping () -> Child
    ) {
        self.impl = {
            state, action in
            if let action = path.extract(from: action),
               var childValue = state[keyPath: substate] {
                
                let effect = reducer().reduce(state: &childValue, action: action)
                state[keyPath: substate] = childValue
                return effect.map({ rewrap(effect: $0, using: path) })
                
            } else {
                return .none
            }
        }
    }

    /// Initializes the reducer with a keypath from local to child state, and a child `reducer` used to reduce child state.
    /// - Parameters:
    ///   - substate: a keypath from local to child state
    ///   - action: a casepath matching a local action wrapping a child action
    ///   - reducer: a child state reducer
    public init<Child: Reducer>(
        _ substate: WritableKeyPath<State, Child.State>,
        action path: AnyCasePath<Action, Child.Action>,
        reducer: @autoclosure @escaping () -> Child
    ) {
        self.impl = {
            state, action in
            if let action = path.extract(from: action),
               let effect = reducer().reduce(state: &state[keyPath: substate], action: action) {
                return rewrap(effect: effect, using: path)
                
            } else {
                return .none
            }
        }
    }
    
    /// Initializes the reducer with a keypath from local to child state, and a child `reducer` used to reduce child state
    /// **if child state is not nil**.
    /// - Parameters:
    ///   - substate: a keypath from local to child state
    ///   - action: a casepath matching a local action wrapping a child action
    ///   - reducer: a child state reducer
    public init<Child: Reducer>(
        _ substate: WritableKeyPath<State, Child.State?>,
        action path: AnyCasePath<Action, Child.Action>,
        reducer: @autoclosure @escaping () -> Child
    ) {
        self.impl = {
            state, action in
            if let action = path.extract(from: action),
               var childValue = state[keyPath: substate] {
                
                let effect = reducer().reduce(state: &childValue, action: action)
                state[keyPath: substate] = childValue
                return effect.map({ rewrap(effect: $0, using: path) })
                
            } else {
                return .none
            }
        }
    }

    public func reduce(state: inout State, action: Action) -> Effect<Action>? {
        impl(&state, action)
    }
}

/// Rewrites `Child` effects as equivalent `Parent` effects using parent action case path `path`.
///
/// Application state is typically expressed as a hierarchy of substates, each reduced by their own reducer types.
/// To reduce this type of compex application state, reducers themselves can be expressed as hierarchies containing
/// both parent and child reducers..
///
/// This raises the question - how do you express an action targetted at some reducer deep within a reducer
/// hierarchy? The answer: wrapped actions.
///
/// ```swift
/// struct Parent: Reducer {
///     struct State: States {
///         // ...
///         var childState: Child.State
///     }
///     enum Action: Actions {
///         case parentAction1
///         case parentAction2
///         case childAction(Child.Action)
///     }
///     var body: some Reducer<State, Action> {
///         Reduce {
///             state, action in
///             // reduce parent state here
///         }
///         // reduce child states using the ReduceChild body reducer
///         ReduceChild(\.childState, /Action.childAction, Child())
///     }
/// }
///
/// struct Child: Reducer {
///     struct State: States {
///         // ...
///     }
///     enum Action: Actions {
///         case childAction1
///         case childAction2
///     }
///     // ...
/// }
/// ```
///
/// In the parent/child reducer arrangement shown above, actions intended for the child can be expressed
/// by composing both parent and child actions like so: `.childAction(.childAction2)`.
///
/// The ReduceChild body reducer needs to rewrite `Effect<Child.Action>` reducer function results as
/// `Effect<Parent.Action>` results, in order to compose a well-formed parent reducer.
///
/// The `rewrap(effect:using:)` function performs this rewrite.
///
/// - Parameters:
///   - effect: a child action effect
///   - path: a case path for parent actions embedding a child action
/// - Returns: a parent action effect
private func rewrap<Parent: Actions, Child: Actions>(effect: Effect<Child>, using path: AnyCasePath<Parent, Child>) -> Effect<Parent> {
    return Effect(operation: rewrap(operation: effect.operation, using: path))
}

private func rewrap<Parent: Actions, Child: Actions>(operation: Effect<Child>.Operation, using path: AnyCasePath<Parent, Child>) -> Effect<Parent>.Operation {
    switch operation {
    case let .one(op):
        return .one {
            path.embed(await op())
        }
        
    case let .many(op):
        return .many {
            yield in await op({ action in yield(path.embed(action)) })
        }
        
    case let .compound(ops):
        return .compound(ops.map({ rewrap(operation: $0, using: path) }))
        
    case let .cancellable(name, op):
        return .cancellable(name, rewrap(operation: op, using: path))
        
    case let .cancel(name):
        return .cancel(name)
        
    case let .forget(name):
        return .forget(name)
    }
}


