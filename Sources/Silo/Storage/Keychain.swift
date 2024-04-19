//
//  Keychain.swift
//  Fastr
//
//  Created by Mark Onyschuk on 2022-12-05.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import SwiftUI

/// Keychain-backed persistent key/value containers
public protocol KeychainContainers {
    func read(_ key: String) -> Data?
    func write(_ key: String, _ value: Data?)
}

extension KeychainContainers {
    public func read<Value>(_ key: String) -> Value? where Value: Codable {
        read(key).flatMap {
            data in
            try? JSONDecoder().decode(Value.self, from: data)
        }
    }
    public func write<Value>(_ key: String, _ value: Value?) where Value: Codable {
        write(
            key,
            value.flatMap {
                value in
                try? JSONEncoder().encode(value)
            }
        )
    }
}

/// A keychain-backed persistent key/value container
public struct KeychainContainer: KeychainContainers {
    /// the container's associated service, typically the app's identifier
    private let service: String
    /// the container's associated access group, used to identify a keychain group shared between multiple applications
    private let accessGroup: String?
    
    /// Initializes a new `KeychainContainer` for a given `service`, typically an app identifier.
    ///
    /// If `accessGroup` is specified, then the keychain used will be one that has been configured to be shared
    /// between multiple applications (`service`s).
    ///
    /// - Parameters:
    ///   - service: the item's associated service, typically the app's identifier
    ///   - accessGroup: the item's associated access group, used to identify a keychain group shared between multiple applications.
    public init(service: String, accessGroup: String? = nil) {
        self.service     = service
        self.accessGroup = accessGroup
    }
    
    // MARK: - KeychainContainers
    
    /// reads the item's value from its assocated keychain
    /// - Returns: a `Data` value, or nil if the item does not exist on the keychain
    public func read(_ key: String) -> Data? {
        /*
         Build a query to find the item that matches the service, account and
         access group.
         */
        var query = Self.query(service: service, account: key, accessGroup: accessGroup)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        
        // Try to fetch the existing keychain item that matches the query.
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        // Check the return status and throw an error if appropriate.
        guard status != errSecItemNotFound else { return nil }
        guard status == noErr else { return nil }
        
        // Parse the password string from the query result.
        guard let existingItem = queryResult as? [String: AnyObject],
              let data = existingItem[kSecValueData as String] as? Data
        else {
            return nil
        }
        
        return data
    }
    
    /// writes, or removes the item's value from its associated keychain
    /// - Parameter value: the `Data` value to write, or nil if the item is to be removed from the keychain
    public func write(_ key: String, _ data: Data?) {
        if let data {
            if read(key) != nil {
                var attributesToUpdate = [String: AnyObject]()
                attributesToUpdate[kSecValueData as String] = data as AnyObject?
                
                let query = Self.query(service: service,
                                                    account: key,
                                                    accessGroup: accessGroup)
                _ = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            } else {
                var newItem = Self.query(service: service,
                                                      account: key,
                                                      accessGroup: accessGroup)
                
                newItem[kSecValueData as String] = data as AnyObject?
                
                _ = SecItemAdd(newItem as CFDictionary, nil)
            }
        } else {
            let query = Self.query(service: service, account: key, accessGroup: accessGroup)
            
            _ = SecItemDelete(query as CFDictionary)
        }
    }
    
    /// constructs a keychain query
    private static func query(
        service:     String,
        account:     String? = nil,
        accessGroup: String? = nil
    ) -> [String: AnyObject] {
        
        var query = [String: AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service as AnyObject?
        
        if let account {
            query[kSecAttrAccount as String] = account as AnyObject?
        }
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
        }
        
        return query
    }
}

public final class MockKeychainContainer: KeychainContainers {
    private var values: [String: Data] = [:]
    
    public func read(_ key: String) -> Data? {
        values[key]
    }
    public func write(_ key: String, _ value: Data?) {
        values[key] = value
    }
    public init<Value>(key: String, value: Value?) where Value: Codable {
        if let data = try? JSONEncoder().encode(value) {
            values[key] = data
        }
    }
}

/// A keychain value stored by key, within some keychain-backed container
public struct KeychainItem<Value> where Value: Codable {
    public let key: String
    private let container: KeychainContainers
    
    public var value: Value? {
        get { container.read(key) }
        nonmutating set { container.write(key, newValue )}
    }
    
    /// Creates an item stored in the keychain identified by `service`
    ///
    /// When unspecified, `service` is assumed to equal `Bundle.main.bundleIdentifier` - the current app identifier.
    ///
    /// - Parameter key: an item key
    /// - Parameter service: a keychain service name
    /// - Returns: a keychain item
    public static func local(_ key: String, service: String? = nil) -> Self {
        return Self(key: key, container: KeychainContainer(service: service ?? Bundle.main.bundleIdentifier!))
    }

    /// Creates an item stored in the shared keychain identified by `service` with access group `accessGroup`
    ///
    /// When unspecified, `service` is assumed to equal `Bundle.main.bundleIdentifier` - the current  app identifier.
    ///
    /// - Parameter key: an item key
    /// - Parameter service: a keychain service name
    /// - Parameter accessGroup: a keychain access group
    /// - Returns: a keychain item
    public static func shared(_ key: String, service: String? = nil, accessGroup: String) -> Self {
        return Self(key: key, container: KeychainContainer(service: service ?? Bundle.main.bundleIdentifier!, accessGroup: accessGroup))
    }
                    
    public static func mock(_ key: String, value: Value? = nil) -> Self {
        return Self(key: key, container: MockKeychainContainer(key: key, value: value))
    }
}

// MARK: - Property Wrapper

/// A property wrapper for keychain-backed values
@propertyWrapper
public struct Keychain<Value> where Value: Codable {
    private let item: KeychainItem<Value>
    private let value: Value

    public var wrappedValue: Value {
        get { item.value ?? value }
        nonmutating set { item.value = newValue }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: { item.value ?? value },
            set: { newValue in item.value = newValue }
        )
    }
    
    /// Creates a wrapper for a keychain value.
    ///
    /// Where no keychain value is defined by the user, then `value` is used in its place, or `nil`
    /// if value itself is left unspecified.
    /// - Parameters:
    ///   - item: a combination key and container used to store the value
    ///   - default: a default value used as the wrapped value when no default value is defined by the user, or `nil` if unspecified
    public init(wrappedValue: Value, _ item: KeychainItem<Value>) {
        self.item = item
        self.value = wrappedValue
    }

    public init(wrappedValue: Value, _ item: InjectableKeychain<Value>) {
        self.item = item()
        self.value = wrappedValue
    }
}

extension Keychain where Value: ExpressibleByNilLiteral {
    /// Creates a wrapper for a keychain value.
    ///
    /// Where no keychain value is defined by the user, then `value` is used in its place, or `nil`
    /// if value itself is left unspecified.
    /// - Parameters:
    ///   - key: a combination key and container used to store the value
    ///   - default: a default value used as the wrapped value when no default value is defined by the user, or `nil` if unspecified
    public init(wrappedValue: Value = nil, _ item: KeychainItem<Value>) {
        self.item = item
        self.value = wrappedValue
    }
    
    public init(wrappedValue: Value = nil, _ item: InjectableKeychain<Value>) {
        self.item = item()
        self.value = wrappedValue
    }
}
