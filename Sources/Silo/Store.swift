//
//  Store.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-10-29.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Combine
import Foundation

/// A state container
@dynamicMemberLookup
public final class Store<Reducer>: ObservableObject where Reducer: Silo.Reducer {
    private let reducer: Reducer
    private var tasks = [AnyHashable:AnyTask]()

    public typealias State = Reducer.State
    public typealias Action = Reducer.Action
    
    /// current state
    var mutex = Mutex()
    var get: () -> State
    var set: (State) -> Void

    public var objectDidChange  = ObservableStorePublisher()
    public var objectWillChange = ObservableStorePublisher()

    public var state: State {
        get {
            mutex.locked { get() }
        }
        set {
            objectWillChange.send()
            mutex.locked { set(newValue) }
            objectDidChange.send()
        }
    }
    
    /// Initializes the store with a reducer and starting state
    /// - Parameters:
    ///   - reducer: a reducer
    ///   - state: a starting state
    public init(_ reducer: Reducer, state: State) {
        self.reducer = reducer
        
        var value = state
        
        self.get = { value }
        self.set = { value = $0 }
    }

    /// Initializes the store with a reducer and starting state derived from a parent store.
    ///
    /// Stores initialized from a parent access the same underlying state so that changes in
    /// ether the parent or child stores are reflected in both.
    ///
    /// - Parameters:
    ///   - reducer: a reducer
    ///   - parent: a parent state
    ///   - keyPath: a keypath from parent state to reducer state
    public init<Parent>(_ reducer: Reducer, parent: Store<Parent>, keyPath: WritableKeyPath<Parent.State, State>) {
        self.reducer = reducer
        
        self.get = { parent.state[keyPath: keyPath] }
        self.set = { parent.state[keyPath: keyPath] = $0 }
    }

    deinit {
        cancelAll()
    }
    
    /// Reduces `action` onto `state`, then executes any returned `Effect`.
    /// - Parameter action: an action to reduce onto `state`
    public func dispatch(_ action: Action) {
        mutex.locked {
            let effect = reducer.reduce(state: &state, action: action)
            if let effect { execute(operation: effect.operation) }
        }
    }
    
    // MARK: - DynamicMemberLookup
    public subscript<T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
        return state[keyPath: keyPath]
    }
    
    @MainActor
    private func observe(_ action: Action) {
        dispatch(action)
    }

    @discardableResult
    func execute(operation: Effect<Action>.Operation) -> Task<(), Never> {
        switch operation {
        case let .one(op):
            return Task {
                [weak self] in
                
                let action = await op()
                if let self {
                    await self.observe(action)
                }
            }
        case let .many(ops):
            return Task {
                [weak self] in

                for await action in AsyncStream(builder: ops) {
                    if let self {
                        await self.observe(action)
                    }
                }
            }
            
        case let .cancel(name):
            cancel(name)
            return Task {}
        
        case let .forget(name):
            forget(name)
            return Task {}
            
        case let .compound(ops):
            return Task {
                [weak self] in

                await withTaskGroup(of: Void.self) {
                    group in
                    if let execute = self?.execute {
                        for task in ops.map(execute) {
                            group.addTask {
                                _ = await task.result
                            }
                        }
                    }
                }
            }
            
        case let .cancellable(name, op):
            return Task {
                [weak self] in

                if let task = self?.execute(operation: op) {
                    self?.register(task: task.eraseToAnyTask(), name: name)
                    
                    let _ = await task.result
                    self?.forget(name)
                }
            }
        }
    }

    /// Registers a cancellable, type erased task.
    /// - Parameters:
    ///   - task: a type erased task
    ///   - name: a unique identifier for the task
    func register(task: AnyTask, name: AnyHashable) {
        tasks[name] = task
    }
    
    /// Cancels a previously registered task
    /// - Parameter name: the unique identifier for the task
    func cancel(_ name: AnyHashable) {
        if let task = tasks[name] {
            tasks[name] = nil
            task.cancel()
        }
    }
    
    
    /// Cancel all active tasks
    func cancelAll() {
        tasks.values.forEach { task in task.cancel() }
        tasks.removeAll()
    }
    
    /// Forgets a previously registered task.
    ///
    /// Unlike cancel, `forget` unregisters the task but allows it to complete.
    /// Once forgotten, a task can no longer be cancelled.
    ///
    /// - Parameter name: the unique identifier for the task.
    func forget(_ name: AnyHashable) {
        tasks[name] = nil
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


/// A Publisher used to notify of `Store` state changes.
public final class ObservableStorePublisher: Publisher {
    public typealias Output = Void
    public typealias Failure = Never
    
    /// if `true` then state change updates are silenced.
    ///
    /// Used by `WithSubstate` SwiftUI view to selectively observe state changes
    /// of store substates using `Store`s `objectDidChange` publisher.
    public var isSilenced = false
    private var impl = PassthroughSubject<Void, Never>()
    
    public func send() {
        if !isSilenced { impl.send() }
    }
    public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Void == S.Input {
        impl.receive(subscriber: subscriber)
    }
}
