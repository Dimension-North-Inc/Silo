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
public struct ReduceChildren<State: States, Action: Actions & CasePathable>: SubstateReducer {
    var impl: (inout State, Action) -> Effect<Action>? = { _, _ in .none }

    /// Initializes the reducer with a keypath from local to child state, and a child `reducer` used to reduce child state.
    /// - Parameters:
    ///   - substate: a keypath from local to child state
    ///   - action: a casepath matching a local action wrapping a child action
    ///   - reducer: a child state reducer
    public init<Child: Reducer, ID: Hashable & Sendable>(
        _ substate: WritableKeyPath<State, IdentifiedArray<ID, Child.State>>,
        action path: CaseKeyPath<Action, (ID, Child.Action)>,
        reducer: Child
    ) {
        self.impl = {
            state, action in
            if let (id, action) = action[case: path],
               var childValue = state[keyPath: substate][id: id] {
                let effect = reducer.reduce(state: &childValue, action: action)
                state[keyPath: substate][id: id] = childValue
                return effect.map({ rewrap(effect: $0, using: path, id: id) })
            } else {
                return .none
            }
        }
    }

    public func reduce(state: inout State, action: Action) -> Effect<Action>? {
        impl(&state, action)
    }
}

/// Rewrites `Child` actions as equivalent `Parent` actions using parent action case path `path`.
///
/// - Parameters:
///   - effect: a child action effect
///   - path: a case path for parent actions embedding a child action
/// - Returns: a parent action effect
func rewrap<Parent: Actions, Child: Actions, ID: Hashable & Sendable>(effect: Effect<Child>, using path: CaseKeyPath<Parent, (ID, Child)>, id: ID) -> Effect<Parent> {
    return Effect(operation: rewrap(operation: effect.operation, using: path, id: id))
}

func rewrap<Parent: Actions, Child: Actions, ID: Hashable & Sendable>(operation: Effect<Child>.Operation, using path: CaseKeyPath<Parent, (ID, Child)>, id: ID) -> Effect<Parent>.Operation {
    switch operation {
    case let .one(op):
        return .one {
            path((id, await op()))
        }
        
    case let .many(op):
        return .many {
            yield in await op({ action in yield(path((id, action))) })
        }
        
    case let .compound(ops):
        return .compound(ops.map({ rewrap(operation: $0, using: path, id: id) }))
        
    case let .cancellable(name, op):
        return .cancellable(name, rewrap(operation: op, using: path, id: id))
        
    case let .cancel(name):
        return .cancel(name)
        
    case let .forget(name):
        return .forget(name)
    }
}
