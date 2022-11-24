//
//  OptionalChild.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-10-30.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

/// A reducer which executes a `Child` reducer on substates.
public struct ReduceOptionalChild<State: States, Action: Actions>: Reducer {
    var impl: (inout State, any Actions) -> Effect<any Actions>?
    
    /// Initializes the reducer with a `substate` keypath from local to child states, and a `child` reducer used to reduce child state.
    /// - Parameters:
    ///   - substate: a keypath from local to child state
    ///   - child: a child state reducer
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

    public var isSubstateReducer: Bool {
        return true
    }
}
