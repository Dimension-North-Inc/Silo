//
//  DependencyContainer.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-12-03.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

public protocol DependencyKey {
    associatedtype Value = Self
    static var defaultValue: Value { get }
}

public final class DependencyValues {
    private var mutex = Mutex()
    private var stack: [[ObjectIdentifier: any Sendable]] = [[:]]

    public subscript<Key: DependencyKey>(key: Key.Type) -> Key.Value {
        get {
            mutex.locked {
                for values in stack.reversed() {
                    if let dependency = values[ObjectIdentifier(key)] as? Key.Value {
                        return dependency
                    }
                }
                return key.defaultValue
            }
        }
        set {
            mutex.locked {
                if stack.isEmpty {
                    stack.append([ObjectIdentifier(key): newValue])
                } else {
                    stack[stack.count - 1][ObjectIdentifier(key)] = newValue
                }
            }
        }
    }

    private func pushing(_ config: (DependencyValues) -> Void, perform: () -> Void) {
        mutex.locked {
            stack.append([:])
            config(self)
            perform()
            stack.removeLast()
        }
    }
    
    public static func pushing(_ config: (DependencyValues) -> Void, execute: () -> Void) {
        shared.pushing(config, perform: execute)
    }

    static var shared = DependencyValues()
}

