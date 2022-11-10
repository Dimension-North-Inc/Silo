//
//  Store.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-10-29.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

/// A state container
@dynamicMemberLookup
public final class Store<Reducer>: ObservableObject  where Reducer: Silo.Reducer {
    private var mutex = Mutex()
    private var tasks = TaskStore()

    private var reducer: Reducer
    
    public typealias State  = Reducer.State
    public typealias Action = Reducer.Action
    
    /// current state
    @Published
    var state: State
    
    /// Initializes the store with a reducer and starting state
    /// - Parameters:
    ///   - reducer: a reducer
    ///   - state: a starting state
    public init(_ reducer: Reducer, state: State) {
        self.reducer = reducer
        self.state   = state
    }
    
    deinit {
        self.tasks.cancelAll()
    }

    /// Reduces `action` onto `state`, then executes any returned `Effect`.
    /// - Parameter action: an action to reduce onto `state`
    public func dispatch(_ action: Action) {
        mutex.locked {
            let effect = reducer.reduce(state: &state, action: action)
            if let effect { execute(operation: effect.operation) }
        }
    }

    /// Reduces `action` onto `state`, then executes any returned `Effect`.
    /// - Parameter action: an action to reduce onto `state`
    public func dispatch(_ action: any Actions) {
        mutex.locked {
            let effect = reducer.reduce(state: &state, action: action)
            if let effect { execute(operation: effect.operation) }
        }
    }
    
    @MainActor
    private func observe(_ action: any Actions) {
        dispatch(action)
    }
    
    @discardableResult
    internal func execute(operation: Effect<any Actions>.Operation) -> Task<(), Never> {
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
            tasks.cancel(name)
            return Task {}
        
        case let .forget(name):
            tasks.forget(name)
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
                    self?.tasks.register(task: task.eraseToAnyTask(), name: name)
                    
                    let _ = await task.result
                    self?.tasks.forget(name)
                }
            }
        }
    }

    // MARK: - DynamicMemberLookup
    public subscript<T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
        return state[keyPath: keyPath]
    }
}
