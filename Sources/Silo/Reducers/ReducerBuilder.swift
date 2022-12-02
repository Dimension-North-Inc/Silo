//
//  ReducerBuilder.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-10-29.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

/// A result builder used to define and compose reducers.
@resultBuilder
public struct ReducerBuilder<State: States, Action: Actions> {
    
    public static func buildArray(
        _ reducers: [some Reducer<State, Action>]
    ) -> some Reducer<State, Action> {
        ArrayReducer(reducers: reducers)
    }
    
    public static func buildBlock(
    ) -> some Reducer<State, Action> {
        EmptyReducer()
    }
    
    @inlinable
    public static func buildBlock(
        _ reducer: some Reducer<State, Action>
    ) -> some Reducer<State, Action> {
        reducer
    }
    
    @inlinable
    public static func buildEither(
        first reducer: some Reducer<State, Action>
    ) -> some Reducer<State, Action> {
        reducer
    }
    
    @inlinable
    public static func buildEither(
        second reducer: some Reducer<State, Action>
    ) -> some Reducer<State, Action> {
        reducer
    }
    
    @inlinable
    public static func buildExpression(
        _ expression: some Reducer<State, Action>
    ) -> some Reducer<State, Action> {
        expression
    }
    
    public static func buildOptional(
        _ wrapped: (some Reducer<State, Action>)?
    ) -> some Reducer<State, Action> {
        OptionalReducer(reducer: wrapped)
    }
    
    @inlinable
    public static func buildPartialBlock(
        first: some Reducer<State, Action>
    ) -> some Reducer<State, Action> {
        first
    }
    
    public static func buildPartialBlock(
        accumulated: some Reducer<State, Action>, next: some Reducer<State, Action>
    ) -> some Reducer<State, Action> {
        switch accumulated {
        case let accumulated as ArrayReducer<State, Action>:
            return ArrayReducer(reducers: accumulated.reducers + [next])
        default:
            return ArrayReducer(reducers: [accumulated, next])
        }
    }
}


// MARK: - Internal Reducer Types

/// An empty reducer.
struct EmptyReducer<State: States, Action: Actions>: Reducer {
    init() {}
    
    func reduce(state: inout State, action: Action) -> Effect<Action>? {
        .none
    }
}

/// A reducer which execute optionally.
struct OptionalReducer<Wrapped: Reducer>: Reducer {
    var reducer: Wrapped?
    init(reducer: Wrapped?) {
        self.reducer = reducer
    }
    
    func reduce(state: inout Wrapped.State, action: Wrapped.Action) -> Effect<Wrapped.Action>? {
        reducer?.reduce(state: &state, action: action) ?? .none
    }
}

/// A reducer which encapsulates arrays of reducers, sorting them so that
/// reducers which operate on substates are executed first relative to reducers
/// which operate on local state.
///
/// Ordering among same state reducers remains unchanged relative to input.
struct ArrayReducer<State: States, Action: Actions>: Reducer {
    var reducers: [any Reducer<State, Action>]
    init(reducers: [any Reducer<State, Action>]) {
        self.reducers = reducers.sorted {
            r1, r2 in
            
            let p1 = r1 is any SubstateReducer ? 0 : 1
            let p2 = r2 is any SubstateReducer ? 0 : 1
            
            return p1 < p2
        }
    }

    func reduce(state: inout State, action: Action) -> Effect<Action>? {
        var effects: [Effect<Action>] = []
        
        // run each reducer
        for reducer in reducers {
            if let effect = reducer.reduce(state: &state, action: action) {
                effects.append(effect)
            }
        }

        // return a combined effect
        if !effects.isEmpty {
            return effects[1...].reduce(effects[0], +)
        } else {
            return .none
        }
    }
}

