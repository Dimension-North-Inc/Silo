//
//  ReduceAny.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-11-23.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation
/// A reducer constructed using a closure meant to reduce actions not directly targeted at the reducer.
public struct ReduceAny<State: States, Action: Actions>: Reducer {
    var impl: (inout State, any Actions) -> Effect<any Actions>?
    public init(impl: @escaping (inout State, any Actions) -> Effect<any Actions>?) {
        self.impl = impl
    }
    public func reduce(state: inout State, action: Action) -> Effect<Actions>? {
        .none
    }
    public func reduce(state: inout State, action: any Actions) -> Effect<any Actions>? {
        return impl(&state, action)
    }
}
