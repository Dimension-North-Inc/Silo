//
//  Mutex.swift
//  Silo
//
//  Created by Mark Onyschuk on 2018-12-05.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//
//  Adapted from Lock.swift, part of the SwiftNIO open source project
//  Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
//  Licensed under Apache License v2.0
//

import Foundation

/// A pthread-based Mutex
///
/// Protect  sections of code from concurrent execution using `Mutex.locked(_:)`:
///
/// ```swift
///     let lock = Mutex()
///
///     // ...later in code
///     lock.locked {
///         // run one thread at a time...
///     }
/// ```
///
/// - Note: Implements best-practice for work with `pthread_mutex_t` as described
/// [here](https://forums.swift.org/t/thread-sanitiser-v-mutex/54515/3).
public final class Mutex {
    fileprivate let mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)

    /// Initializes the mutex
    public init() {
        var attr = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)

        let err = pthread_mutex_init(self.mutex, &attr)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
    }

    deinit {
        let err = pthread_mutex_destroy(self.mutex)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")

        mutex.deallocate()
    }

    /// Acquires the lock.
    ///
    /// Use `locked(_:)` instead of this method and `unlock`, to simplify lock handling.
    public func lock() {
        let err = pthread_mutex_lock(self.mutex)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
    }

    /// Releases the lock.
    ///
    /// Use `locked(_:)` instead of this method and `lock`, to simplify lock handling.
    public func unlock() {
        let err = pthread_mutex_unlock(self.mutex)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
    }

    /// Acquire the lock for the duration of the given closure.
    ///
    /// - Parameter body: The closure to execute while holding the lock.
    /// - Returns: The value returned by the block.
    @inlinable
    public func locked<T>(_ body: () throws -> T) rethrows -> T {
        self.lock()
        defer { self.unlock() }
        
        return try body()
    }
}
