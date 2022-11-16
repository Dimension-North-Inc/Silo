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
public final class Store<Reducer>: ObservableObject  where Reducer: Silo.Reducer {
    private let reducer: Reducer
    private var tasks = [AnyHashable:AnyTask]()

    public typealias State  = Reducer.State
    public typealias Action = Reducer.Action
    
    /// current state
    var state: StateStorage<State>
    var stateObserver: AnyCancellable?
    
    /// Initializes the store with a reducer and starting state
    /// - Parameters:
    ///   - reducer: a reducer
    ///   - state: a starting state
    public init(_ reducer: Reducer, state: State) {
        self.reducer = reducer
        
        self.state = StateStorage(state)
        self.stateObserver = self.state.objectWillChange.sink {
            [weak self] in self?.objectWillChange.send()
        }
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
        
        self.state = StateStorage(parent.state, keyPath: keyPath)
        self.stateObserver = self.state.objectWillChange.sink {
            [weak self] in self?.objectWillChange.send()
        }
    }

    deinit {
        cancelAll()
    }
    
    /// Reduces `action` onto `state`, then executes any returned `Effect`.
    /// - Parameter action: an action to reduce onto `state`
    public func dispatch(_ action: Action) {
        state.mutex.locked {
            let effect = reducer.reduce(state: &state.value, action: action)
            if let effect { execute(operation: effect.operation) }
        }
    }

    /// Reduces `action` onto `state`, then executes any returned `Effect`.
    /// - Parameter action: an action to reduce onto `state`
    public func dispatch(_ action: any Actions) {
        state.mutex.locked {
            let effect = reducer.reduce(state: &state.value, action: action)
            if let effect { execute(operation: effect.operation) }
        }
    }
    
    // MARK: - DynamicMemberLookup
    public subscript<T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
        return state.value[keyPath: keyPath]
    }
    
    @MainActor
    private func observe(_ action: any Actions) {
        dispatch(action)
    }

    @discardableResult
    func execute(operation: Effect<any Actions>.Operation) -> Task<(), Never> {
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


// MARK: - StateStorage
final class StateStorage<State>: ObservableObject where State: States {
    enum Container {
        case base(State)
        case derived(getter: () -> State, setter: (State) -> Void)
    }
    
    /// storage lock
    let mutex: Mutex

    @Published
    var container: Container
    
    /// storage value
    var value: State {
        get {
            mutex.locked {
                switch container {
                case let .base(state): return state
                case let .derived(getter, _): return getter()
                }
            }
        }
        set {
            mutex.locked {
                switch container {
                case .base(_): container = .base(newValue)
                case let .derived(_, setter): setter(newValue)
                }
            }
        }
    }
    
    /// Initialize storage with value `state`
    /// - Parameter state: stored state
    init(_ state: State) {
        self.mutex = Mutex()
        self.container = .base(state)
    }
    
    /// Initializes storage from substate of some `Parent` state.
    /// - Parameters:
    ///   - parent: parent state storage
    ///   - keyPath: a keypath to parent substate
    init<Parent>(_ parent: StateStorage<Parent>, keyPath: WritableKeyPath<Parent, State>) {
        self.mutex = parent.mutex
        self.container = .derived(
            getter: { parent.value[keyPath: keyPath] },
            setter: { value in parent.value[keyPath: keyPath] = value }
        )
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
