//
//  ReduceChild.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-10-30.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

/// A `body` reducer which executes a `Child` reducer on substate identified by keypath.
///
/// Where substate is `nil`, the reducer does not execute.
public struct ReduceChild<State: States, Action: Actions>: SubstateReducer {
    var impl: (inout State, any Actions) -> Effect<any Actions>?
    
    /// Initializes the reducer with a keypath from local to child state, and a child `reducer` used to reduce child state.
    /// - Parameters:
    ///   - substate: a keypath from local to child state
    ///   - reducer: a child state reducer
    public init<Child>(state substate: WritableKeyPath<State, Child.State>, reducer: Child) where Child: Reducer {
        self.impl = {
            state, action in
            reducer.reduce(state: &state[keyPath: substate], action: action)
        }
    }
    
    /// Initializes the reducer with a keypath from local to child state, and a child `reducer` used to reduce child state
    /// **if child state is not nil**.
    /// - Parameters:
    ///   - substate: a keypath from local to child state
    ///   - reducer: a child state reducer
    public init<Child>(state substate: WritableKeyPath<State, Child.State?>, reducer: Child) where Child: Reducer {
        self.impl = {
            state, action in
            if var subs = state[keyPath: substate] {
                let effect = reducer.reduce(state: &subs, action: action)
                state[keyPath: substate] = subs
                return effect
            } else {
                return .none
            }
        }
    }

    public func reduce(state: inout State, action: Action) -> Effect<any Actions>? {
        .none
    }
    public func reduce(state: inout State, action: any Actions) -> Effect<any Actions>? {
        impl(&state, action)
    }
}
