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
        action path: CasePath<Action, (Child.Action)>,
        @ReducerBuilder<Child.State, Child.Action> reducer: () -> Child
    ) {
        let child = reducer()
        
        self.impl = {
            state, action in
            if let action = path.extract(from: action) {
                return child.reduce(state: &state[keyPath: substate], action: action)
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
        action path: CasePath<Action, (Child.Action)>,
        @ReducerBuilder<Child.State, Child.Action> reducer: () -> Child
    ) {
        let child = reducer()
        
        self.impl = {
            state, action in
            if let action = path.extract(from: action),
               var childValue = state[keyPath: substate] {
                let effect = child.reduce(state: &childValue, action: action)
                state[keyPath: substate] = childValue
                return effect
            } else {
                return .none
            }
        }
    }

    public func reduce(state: inout State, action: Action) -> Effect<any Actions>? {
        impl(&state, action)
    }
}
