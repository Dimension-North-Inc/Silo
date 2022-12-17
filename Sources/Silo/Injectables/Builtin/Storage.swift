//
//  Storage.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-12-16.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation
/// An Injectable DefaultItem
public typealias InjectableDefault<Value> = Injectable<DefaultItem<Value>> where Value: Codable

/// An Injectable KeychainItem
public typealias InjectableKeychain<Value> = Injectable<KeychainItem<Value>> where Value: Codable

extension Builtins {
    /// Creates a new Injectable DefaultItem
    /// - Parameter item: a default item
    /// - Returns: a new injectable
    public static func `default`<Value: Codable>(_ item: DefaultItem<Value>) -> InjectableDefault<Value> {
        return Injectable { item }
    }
    
    /// Creates a new Injectable KeychainItem
    /// - Parameter item: a keychain item
    /// - Returns: a new injectable
    public static func keychain<Value: Codable>(_ item: KeychainItem<Value>) -> InjectableKeychain<Value> {
        return Injectable { item }
    }
}
