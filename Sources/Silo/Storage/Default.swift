//
//  Default.swift
//  Fastr
//
//  Created by Mark Onyschuk on 2022-12-05.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import SwiftUI

/// Persistent user default value containers
public protocol DefaultContainers {
    func read(key: String) -> String?
    func write(_ value: String?, key: String)
    
    func clear(key: String)
}

extension DefaultContainers {
    public func read<Value>(key: String) -> Value? where Value: Codable {
        read(key: key)
            .flatMap { $0.data(using: .utf8) }
            .flatMap { try? JSONDecoder().decode(Value.self, from: $0) }
    }
    public func write<Value>(_ value: Value?, key: String) where Value: Codable {
        write(
            value
                .flatMap { try? JSONEncoder().encode($0) }
                .flatMap { String(data: $0, encoding: .utf8) },
            key: key
        )
    }
}

extension UserDefaults: DefaultContainers {
    public func read(key: String) -> String? {
        string(forKey: key)
    }
    public func write(_ value: String?, key: String) {
        set(value, forKey: key)
    }
    public func clear(key: String) {
        removeObject(forKey: key)
    }
}

extension NSUbiquitousKeyValueStore: DefaultContainers {
    public func read(key: String) -> String? {
        string(forKey: key)
    }
    public func write(_ value: String?, key: String) {
        set(value, forKey: key)
    }
    public func clear(key: String) {
        removeObject(forKey: key)
    }
}

public final class MockDefaultContainer: DefaultContainers {
    private var values: [String:String] = [:]

    public func read(key: String) -> String? {
        return values[key]
    }
    public func write(_ value: String?, key: String) {
        values[key] = value
    }
    public func clear(key: String) {
        values.removeAll()
    }
}

/// A user default stored by key, within some persistent container
public struct DefaultItem<Value> where Value: Codable {
    public let key: String
    private let container: DefaultContainers
    
    /// the receiver's stored value
    public var value: Value? {
        get { container.read(key: key) }
        nonmutating set { container.write(newValue, key: key) }
    }
    
    /// Clears the receiver's underlying container
    public func clear() {
        container.clear(key: key)
    }
    
    /// Creates a keyed user default item stored in `container`
    /// - Parameters:
    ///   - key: an item key
    ///   - container: a item container
    public init(key: String, container: DefaultContainers = UserDefaults.standard) {
        self.key = key
        self.container = container
    }
    
    /// Creates a keyed user default item stored in `UserDefaults.standard`
    /// - Parameter key: an item key
    /// - Returns: a default item
    public static func local(_ key: String) -> DefaultItem {
        DefaultItem(key: key, container: UserDefaults.standard)
    }

    /// Creates a keyed user default item stored in `NSUbiquitousKeyValueStore.default`
    /// - Parameter key: an item key
    /// - Returns: a default item
    public static func cloud(_ key: String) -> DefaultItem {
        DefaultItem(key: key, container: NSUbiquitousKeyValueStore.default)
    }
    
    public static func mock(_ key: String) -> DefaultItem {
        DefaultItem(key: key, container: MockDefaultContainer())
    }
}

/// A property wrapper for  persistent user default values
@propertyWrapper
public struct Default<Value> where Value: Codable {
    private let item: DefaultItem<Value>
    private let value: Value
    
    public var wrappedValue: Value {
        get             { item.value ?? value }
        nonmutating set { item.value = newValue }
    }
    
    public var projectedValue: Binding<Value> {
        return Binding(
            get: { item.value ?? value },
            set: { newValue in item.value = newValue }
        )
    }
    
    /// Creates a wrapper for a persistent user default.
    ///
    /// Where no default value is defined by the user, then `value` is used in its place.
    /// - Parameters:
    ///   - key: a combination key and container used to store the value
    ///   - default: a default value used as the wrapped value when no default value is defined by the user
    public init(wrappedValue: Value, _ key: DefaultItem<Value>) {
        self.item = key
        self.value = wrappedValue
    }
    
    public init(wrappedValue: Value, _ key: InjectableDefault<Value>) {
        self.item = key()
        self.value = wrappedValue
    }
}

extension Default where Value: ExpressibleByNilLiteral {
    /// Creates a wrapper for a persistent user default.
    ///
    /// Where no default value is defined by the user, then `value` is used in its place, or `nil`
    /// if value itself is left unspecified.
    /// - Parameters:
    ///   - key: a combination key and container used to store the value
    ///   - default: a default value used as the wrapped value when no default value is defined by the user, or `nil` if unspecified
    public init(wrappedValue: Value = nil, _ key: DefaultItem<Value>) {
        self.item = key
        self.value = wrappedValue
    }
    
    public init(wrappedValue: Value = nil, _ key: InjectableDefault<Value>) {
        self.item = key()
        self.value = wrappedValue
    }
}
