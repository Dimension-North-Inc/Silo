//
//  InContext.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-11-28.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

public struct InContext<State: States, Action: Actions>: Reducer {
    var impl: (inout State, Action) -> Effect<any Actions>?

    public init<Key: ContextKeys, Content: Reducer<State, Action>>(
        key: Key.Type, value: Key.Value,
        @ReducerBuilder<State, Action> reducer: @escaping () -> Content
    ) {
        self.impl = {
            state, action in

            var effect: Effect<any Actions>?
            ContextValues.mutex.locked {
                ContextValues.push(key, value: value)
                effect = reducer().reduce(state: &state, action: action)
                ContextValues.pop(key)
            }
            return effect
        }
    }
    
    public func reduce(state: inout State, action: Action) -> Effect<Actions>? {
        impl(&state, action)
    }
}
