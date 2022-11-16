//
//  Children.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-11-01.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

/// A reducer which operates on `Identifiable` elements among a collection of substates.
public struct ReduceChildren<State: States, Child: Reducer, Substates>: Reducer where Substates: RangeReplaceableCollection, Substates.Element: Identifiable, Substates.Element == Child.State {
    var child: Child
    var substates: WritableKeyPath<State, Substates>
    var identifier: (Child.Action) -> Substates.Element.ID?
    
    /// Creates a new reducer used to modify a `child` state within a collection of `substates`.
    ///
    /// - Parameters:
    ///   - substates: a keypath leading to a collection of substates within the parent state
    ///   - identifier: a function used to extract the substate identifier associated with an action.
    ///   - child: a child state reducer
    public init(
        substates: WritableKeyPath<State, Substates>,
        identifier: @escaping (Child.Action) -> Substates.Element.ID?,
        @ReducerBuilder<Child.State, Child.Action> child: @escaping () -> Child
    ) {
        self.child = child()
        self.substates = substates
        self.identifier = identifier
    }
    
    public func reduce(state: inout State, action: Child.Action) -> Effect<any Actions>? {
        var effect: Effect<any Actions>?
        var children = state[keyPath: substates]
        if let id = identifier(action), let idx = children.firstIndex(where: { $0.id == id }) {
            var selectedChild = children[idx]
            effect = child.reduce(state: &selectedChild, action: action)
            children.replaceSubrange(idx...idx, with: CollectionOfOne(selectedChild))
            state[keyPath: substates] = children
        }
        return effect
    }
    
    public var isSubstateReducer: Bool {
        return true
    }
}
