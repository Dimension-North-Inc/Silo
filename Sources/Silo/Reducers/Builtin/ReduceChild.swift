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
    var impl: (inout State, Action) -> Effect<any Actions>?
    
    /// Initializes the reducer with a keypath from local to child state, and a child `reducer` used to reduce child state.
    /// - Parameters:
    ///   - substate: a keypath from local to child state
    ///   - action: a casepath matching a local action wrapping a child action
    ///   - reducer: a child state reducer
    public init<Child: Reducer>(
        _ substate: WritableKeyPath<State, Child.State>,
        action path: CasePath<Action, Child.Action>,
        @ReducerBuilder<Child.State, Child.Action> reducer: @escaping () -> Child
    ) {
        self.impl = {
            state, action in
            if let action = path.extract(from: action),
               let effect = reducer().reduce(state: &state[keyPath: substate], action: action) {
                
                return effect
                
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
        action path: CasePath<Action, Child.Action>,
        @ReducerBuilder<Child.State, Child.Action> reducer: @escaping () -> Child
    ) {
        self.impl = {
            state, action in
            if let action = path.extract(from: action),
               var childValue = state[keyPath: substate] {
                
                let effect = reducer().reduce(state: &childValue, action: action)
                state[keyPath: substate] = childValue
                return effect
                
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
        action path: CasePath<Action, Child.Action>,
        reducer: @autoclosure @escaping () -> Child
    ) {
        self.impl = {
            state, action in
            if let action = path.extract(from: action),
               let effect = reducer().reduce(state: &state[keyPath: substate], action: action) {
                return effect
                
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
        action path: CasePath<Action, Child.Action>,
        reducer: @autoclosure @escaping () -> Child
    ) {
        self.impl = {
            state, action in
            if let action = path.extract(from: action),
               var childValue = state[keyPath: substate] {
                
                let effect = reducer().reduce(state: &childValue, action: action)
                state[keyPath: substate] = childValue
                return effect
                
            } else {
                return .none
            }
        }
    }

    
    /// Rewrites `Child` actions as equivalent `Parent` actions using parent action case path `path`.
    ///
    /// - Parameters:
    ///   - effect: a child action effect
    ///   - path: a case path for parent actions embedding a child action
    /// - Returns: a parent action effect
    func rewrap<Parent: Actions, Child: Actions>(effect: Effect<Child>, using path: CasePath<Parent, Child>) -> Effect<Parent> {
        return Effect(operation: rewrap(operation: effect.operation, using: path))
    }
    
    func rewrap<Parent: Actions, Child: Actions>(operation: Effect<Child>.Operation, using path: CasePath<Parent, Child>) -> Effect<Parent>.Operation {
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
    

    public func reduce(state: inout State, action: Action) -> Effect<any Actions>? {
        impl(&state, action)
    }
}
