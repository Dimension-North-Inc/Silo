//
//  Reduce.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-10-30.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

/// A reducer constructed using a closure
public struct Reduce<State: States, Action: Actions>: Reducer {
    var impl: (inout State, Action) -> Effect<any Actions>?
    public init(impl: @escaping (inout State, Action) -> Effect<any Actions>?) {
        self.impl = impl
    }
    public func reduce(state: inout State, action: Action) -> Effect<any Actions>? {
        return impl(&state, action)
    }
}
