//
//  Reduce.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-10-30.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

/// A `body` reducer used to reduce local state.
public struct Reduce<State: States, Action: Actions>: Reducer {
    var impl: (inout State, Action) -> Effect<Action>?
    public init(impl: @escaping (inout State, Action) -> Effect<Action>?) {
        self.impl = impl
    }
    public func reduce(state: inout State, action: Action) -> Effect<Action>? {
        return impl(&state, action)
    }
}
