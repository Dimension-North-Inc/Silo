//
//  Children.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-11-01.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

@_exported import CasePaths
@_exported import IdentifiedCollections

/// A  `body` reducer used to reduce one of many `Child`  substates, stored as a collection of `Identifiable` elements.
public struct ReduceChildren<State: States, Action: Actions>: SubstateReducer {
    var impl: (inout State, Action) -> Effect<any Actions>?

    public init<Child: Reducer, ID: Hashable & Sendable>(
        _ substate: WritableKeyPath<State, IdentifiedArray<ID, Child.State>>,
        action path: CasePath<Action, (ID, Child.Action)>,
        @ReducerBuilder<Child.State, Child.Action> reducer: @escaping () -> Child
    ) {
        self.impl = {
            state, action in
            if let (id, action) = path.extract(from: action),
               var childValue = state[keyPath: substate][id: id] {
                let effect = reducer().reduce(state: &childValue, action: action)
                state[keyPath: substate][id: id] = childValue
                return effect
            } else {
                return .none
            }
        }
    }
    
    public init<Child: Reducer, ID: Hashable & Sendable>(
        _ substate: WritableKeyPath<State, IdentifiedArray<ID, Child.State>>,
        action path: CasePath<Action, (ID, Child.Action)>,
        reducer: @autoclosure @escaping () -> Child
    ) {
        self.impl = {
            state, action in
            if let (id, action) = path.extract(from: action),
               var childValue = state[keyPath: substate][id: id] {
                let effect = reducer().reduce(state: &childValue, action: action)
                state[keyPath: substate][id: id] = childValue
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

public struct IdentifiedAction<ID: Hashable & Sendable, Child: Reducer>: Actions {
    var id: ID
    var action: Child.Action
}
