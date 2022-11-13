//
//  Effect.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-10-29.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

public typealias ActionEffect<Action> = () async -> Action
public typealias MultiActionEffect<Action> = (Yield<Action>) async -> Void

/// An asynchronous side-effect, managed and run by a `Store` as result of `Action`s sent to it's associated `reducer`.
public struct Effect<Action> {
    enum Operation {
        case one(ActionEffect<Action>)
        case many(MultiActionEffect<Action>)
        
        case cancel(AnyHashable)
        case forget(AnyHashable)
        
        indirect case compound([Operation])
        indirect case cancellable(AnyHashable, Operation)
    }
    
    var operation: Operation
    init(operation: Operation) {
        self.operation = operation
    }
    
    /// Returns a new effect which can be cancelled using `name`.
    ///
    /// To cancel an executing effect, call `Effects.cancel(_:)`:
    /// ```
    /// switch action {
    /// case .startTicking:
    ///     guard state.ticker == nil else {
    ///         return .none
    ///     }
    ///     state.ticker = UUID()
    ///     return Effect.many {
    ///             send in
    ///             send(.tick)
    ///             while true {
    ///                 try? await Task.sleep(for: .seconds(1))
    ///                 send(.tick)
    ///             }
    ///     }
    ///     .cancelled(using: state.ticker)
    ///
    /// case .stopTicking:
    ///    defer { state.ticker = nil }
    ///    return Effect.cancel(state.ticker)
    ///
    /// case .tick:
    ///    if state.ticker != nil {
    ///        state.value += 1
    ///    }
    ///    return .none
    ///}
    /// ```
    /// - Parameter name: a unique name
    public func cancelled(using name: AnyHashable) -> Self {
        switch operation {
        case .one, .many, .compound:
            return Effect(operation: .cancellable(name, operation))
            
        case .cancel, .forget:
            return Effect(operation: .cancel(name))
            
        case .cancellable(_, let underlying):
            return Effect(operation: .cancellable(name, underlying))
        }
    }
    
    /// Returns an effect that generates a single action when it completes.
    /// - Parameter operation: an asynchronous operation
    /// - Returns: a new effect
    public static func one(operation: @escaping ActionEffect<Action>) -> Effect {
        Effect(operation: .one(operation))
    }
    
    /// Returns an effect that generates multiple actions before completing.
    /// - Parameter operation: an asynchronous operation
    /// - Returns: a new effect
    public static func many(operation: @escaping MultiActionEffect<Action>) -> Effect {
        Effect(operation: .many(operation))
    }
    
    /// Returns as effect used to cancel a previously registered cancellable effect.
    /// - Parameter name: an effect name
    /// - Returns: a new effect
    public static func cancel(_ name: AnyHashable) -> Effect {
        return Effect(operation: .cancel(name))
    }
    
    /// Returns an effect used to forget a previously registered cancellable effect.
    /// - Parameter name: an effect name
    /// - Returns: a new effect.
    public static func forget(_ name: AnyHashable) -> Effect {
        return Effect(operation: .forget(name))
    }
    
    static func +(lhs: Effect, rhs: Effect) -> Effect {
        switch (lhs.operation, rhs.operation) {
        case let (.compound(lhv), .compound(rhv)):
            return Effect(operation: .compound(lhv + rhv))
        case let (.compound(lhv), rhv):
            return Effect(operation: .compound(lhv + [rhv]))
        case let (lhv, .compound(rhv)):
            return Effect(operation: .compound([lhv] + rhv))
        case let (lhv, rhv):
            return Effect(operation: .compound([lhv, rhv]))
        }
    }
}

