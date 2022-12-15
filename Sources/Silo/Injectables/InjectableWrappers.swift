//
//  InjectableWrappers.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-12-14.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

/// A wrapper for  injected properties.
@propertyWrapper public struct Injected<Value> {
    var injectedValue: Value
    public init(_ injected: Injectable<Value>) {
        self.injectedValue = injected()
    }
    public var wrappedValue: Value {
        get { return injectedValue }
        mutating set { injectedValue = newValue }
    }
}

/// A wrapper for lazily injected properties.
///
/// Lazy injected values are only resolved when first accessed.
@propertyWrapper public struct LazyInjected<Value> {
    private var injected: Injectable<Value>
    private var injectedValue: Value!
    private var shouldInitialize = true
    public init(_ injected: Injectable<Value>) {
        self.injected = injected
    }
    public var wrappedValue: Value {
        mutating get {
            if shouldInitialize {
                injectedValue = injected()
                shouldInitialize = false
            }
            return injectedValue
        }
        mutating set {
            injectedValue = newValue
        }
    }
}

/// A wrapper for weak, lazily injected properties.
///
/// Note that `weak` implies that the Injected value is a `class` type.
@propertyWrapper public struct WeakLazyInjected<Value> {
    private var injected: Injectable<Value>
    private weak var injectedValue: AnyObject?
    private var shouldInitialize = true
    public init(_ injected: Injectable<Value>) {
        self.injected = injected
    }
    public var wrappedValue: Value? {
        mutating get {
            if shouldInitialize {
                injectedValue = injected() as AnyObject
                shouldInitialize = false
            }
            return injectedValue as? Value
        }
        mutating set {
            injectedValue = newValue as AnyObject
        }
    }
}
