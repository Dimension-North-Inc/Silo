//
//  Store.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-10-29.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

/// A state container
@dynamicMemberLookup
public final class Store<Reducer>: ObservableObject  where Reducer: Silo.Reducer {
    
    private var mutex = Mutex()
    private var reducer: Reducer
    private var effects: EffectStore?

    public typealias State  = Reducer.State
    public typealias Action = Reducer.Action
    
    /// current state
    @Published
    var state: State
    
    /// Initializes the store with a reducer and starting state
    /// - Parameters:
    ///   - reducer: a reducer
    ///   - state: a starting state
    public init(_ reducer: Reducer, state: State) {
        self.state   = state
        self.reducer = reducer
        self.effects = EffectStore { [weak self] action in self?.dispatch(action) }
    }
    
    /// Reduces `action` onto `state`, then executes any returned `Effect`.
    /// - Parameter action: an action to reduce onto `state`
    public func dispatch(_ action: Action) {
        mutex.locked {
            let effect = reducer.reduce(state: &state, action: action)
            if let effect, let effects { effects.execute(operation: effect.operation) }
        }
    }

    /// Reduces `action` onto `state`, then executes any returned `Effect`.
    /// - Parameter action: an action to reduce onto `state`
    public func dispatch(_ action: any Actions) {
        mutex.locked {
            let effect = reducer.reduce(state: &state, action: action)
            if let effect, let effects { effects.execute(operation: effect.operation) }
        }
    }
    
    // MARK: - DynamicMemberLookup
    public subscript<T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
        return state[keyPath: keyPath]
    }
}
