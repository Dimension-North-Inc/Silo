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
    ///    if state.ticker == nil {
    ///        state.ticker = UUID()
    ///        return Effect
    ///            .run {
    ///                send in
    ///                send(.tick)
    ///                while true {
    ///                    try? await Task.sleep(for: .seconds(1))
    ///                    send(.tick)
    ///                }
    ///            }
    ///            .cancel(using: state.ticker)
    ///    } else {
    ///        return .none
    ///    }
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
    public func cancel(using name: AnyHashable) -> Self {
        switch operation {
        case .one, .many, .compound:
            return Effect(operation: .cancellable(name, operation))

        case .cancel, .forget:
            return Effect(operation: .cancel(name))

        case .cancellable(let named, _) where named == name:
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
}

final class TaskStore {
    private var mutex = Mutex()
    private var tasks = [AnyHashable:AnyTask]()
    
    /// Registers a cancellable, type erased task.
    /// - Parameters:
    ///   - task: a type erased task
    ///   - name: a unique identifier for the task
    func register(task: AnyTask, name: AnyHashable) {
        mutex.locked {
            tasks[name] = task
        }
    }
    
    /// Cancels a previously registered task
    /// - Parameter name: the unique identifier for the task
    func cancel(_ name: AnyHashable) {
        mutex.locked {
            if let task = tasks[name] {
                tasks[name] = nil
                task.cancel()
            }
        }
    }
    
    
    /// Cancel all active tasks
    func cancelAll() {
        mutex.locked {
            tasks.values.forEach { task in task.cancel() }
            tasks.removeAll()
        }
    }
    
    /// Forgets a previously registered task.
    ///
    /// Unlike cancel, `forget` unregisters the task but allows it to complete.
    /// Once forgotten, a task can no longer be cancelled.
    ///
    /// - Parameter name: the unique identifier for the task.
    func forget(_ name: AnyHashable) {
        mutex.locked {
            tasks[name] = nil
        }
    }
    
    deinit {
        cancelAll()
    }
}

/// A type-erased task.
public final class AnyTask {
    /// Call this cancellation block to cancel the task manually.
    public let cancel: () -> Void
    
    /// Checks whether the task is cancelled.
    public var isCancelled: () -> Bool
    
    /// Constructs an AnyTask from the provided Task.
    /// The provided task is held strongly until AnyTask is
    /// deinitted.
    /// - Parameter task: The task to construct with.
    init<S, E>(_ task: Task<S, E>) {
        self.cancel = { task.cancel() }
        self.isCancelled = { task.isCancelled }
    }
}

extension Task {
    public func eraseToAnyTask() -> AnyTask {
        AnyTask(self)
    }
}
