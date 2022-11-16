//
//  ReduceChild.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-10-30.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

/// A reducer which executes a `Child` reducer on substates.
public struct ReduceChild<State: States, Child: Reducer>: Reducer {
    
    /// a child reducer
    var child: Child
    /// a keypath from local to child state
    var substate: WritableKeyPath<State, Child.State>
    
    /// Initializes the reducer with a `substate` keypath from local to child states, and a `child` reducer used to reduce child state.
    /// - Parameters:
    ///   - substate: a keypath from local to child state
    ///   - child: a child state reducer
    public init(
        substate: WritableKeyPath<State, Child.State>,
        @ReducerBuilder<Child.State, Child.Action> child: @escaping () -> Child
    ) {
        self.child = child()
        self.substate = substate
    }
    
    public func reduce(state: inout State, action: Child.Action) -> Effect<any Actions>? {
        return child.reduce(state: &state[keyPath: substate], action: action)
    }

    public var isSubstateReducer: Bool {
        return true
    }
}
