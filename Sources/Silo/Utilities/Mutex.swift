//
//  Mutex.swift
//  Silo
//
//  Created by Mark Onyschuk on 2018-12-05.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

/// A pthread-based Mutex
public final class Mutex {
    private var mutex: pthread_mutex_t = pthread_mutex_t()

    /// initializes the mutex
    public init() {
        var attr: pthread_mutexattr_t = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
#if os(Linux)
        pthread_mutexattr_settype(&attr, Int32(PTHREAD_MUTEX_RECURSIVE))
#else
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
#endif
        switch pthread_mutex_init(&mutex, &attr) {
        case 0: break

        case  EAGAIN: fatalError("EAGAIN - Resource temporarily unavailable")
        case  EINVAL: fatalError("EINVAL - Invalid argument")
        case  ENOMEM: fatalError("ENOMEM - Cannot allocate memory")

        case let err: fatalError("ERROR CODE \(err)")
        }

        pthread_mutexattr_destroy(&attr)
    }

    public func lock() {
        switch pthread_mutex_lock(&mutex) {
        case 0: break

        case  EINVAL: fatalError("EINVAL - Invalid argument")
        case EDEADLK: fatalError("EDEADLK - Resource deadlock avoided")

        case let err: fatalError("ERROR CODE \(err)")
        }
    }

    public func unlock() {
        let ret = pthread_mutex_unlock(&mutex)
        switch ret {
        case 0: break

        case   EPERM: fatalError("EPERM - Operation not permitted")
        case  EINVAL: fatalError("EINVAL - Invalid argument")

        case let err: fatalError("ERROR CODE \(err)")
        }
    }

    deinit {
        assert(
            pthread_mutex_trylock(&self.mutex) == 0
                && pthread_mutex_unlock(&self.mutex) == 0,
            "deinitialization of a locked mutex results in undefined behavior!"
        )

        pthread_mutex_destroy(&self.mutex)
    }

    /// Executes `exec` mutually exclusively
    ///
    /// - Parameter exec: code to execute
    /// - Returns: the result of calling `exec`, if any
    /// - Throws: errors while calling `exec`, if any
    public final func locked<Result>(_ exec: () throws -> Result) rethrows -> Result {
        lock()
        defer { self.unlock() }

        return try exec()
    }
}
