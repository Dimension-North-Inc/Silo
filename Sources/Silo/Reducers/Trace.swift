//
//  Trace.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-10-30.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation
import OSLog

/// A reducer which logs actions, incoming, and outgoing states.
///
/// Tracing produces no output in non-DEBUG builds.
public struct Trace<Wrapped: Reducer>: Reducer {
    public var label: String = "TRACE"
    public var reducer: Wrapped

    public init(label: String = "TRACE", @ReducerBuilder<State, Action> reducer: @escaping () -> Wrapped) {
        self.label = label
        self.reducer = reducer()
    }
    
    #if DEBUG
    @inlinable
    public func reduce(state: inout Wrapped.State, action: any Actions) -> Effect<any Actions>? {
        let prev = state
        let effect = reducer.reduce(state: &state, action: action)
        let next = state
        
        print("[\(label)] action = \(action), prev = \(prev), next = \(next)")
        
        return effect
    }

    @inlinable
    public func reduce(state: inout Wrapped.State, action: Wrapped.Action) -> Effect<any Actions>? {
        let prev = state
        let effect = reducer.reduce(state: &state, action: action)
        let next = state
        
        print("[\(label)] action = \(action), prev = \(prev), next = \(next)")
        
        return effect
    }
        
    #else
    @inlinable
    public func reduce(state: inout Wrapped.State, action: any Actions) -> Effect<any Actions>? {
        reducer.reduce(state: &state, action: action)
    }

    @inlinable
    public func reduce(state: inout Wrapped.State, action: Wrapped.Action) -> Effect<any Actions>? {
        reducer.reduce(state: &state, action: action)
    }
    #endif
}
