//
//  Feature.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-11-01.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

/// A reducer of top-level application features with well-defined initializer and starting state..
public protocol Feature: Reducer {
    /// a default initializer
    init()
    
    /// a default initial state
    static var initial: State { get }
}

extension Store where Reducer: Feature {
    /// Initializes a new `Feature` store with optional initial state.
    /// If no initial state is specified,`Feature.initial` is  used.
    ///
    /// Initializing a store from a `Feature` allows for a simplified initializer:
    ///
    /// ```swift
    ///     let store = Store<MyFeature>()
    /// ```
    ///
    /// - Parameters:
    ///   - reducer: an optional reducer instance
    ///   - state: an optional initial state
    public convenience init(_ reducer: Reducer? = nil, state: Reducer.State? = nil) {
        self.init(reducer ?? Reducer(), state: state ?? Reducer.initial)
    }
}
