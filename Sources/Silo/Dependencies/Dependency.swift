//
//  File.swift
//  
//
//  Created by Mark Onyschuk on 2022-12-03.
//

import Foundation


@propertyWrapper
/// A property wrapper used to access `DependencyValues`.
/// 
public struct Dependency<Value> {
    public var wrappedValue: Value
    
    public init(_ keyPath: KeyPath<DependencyValues, Value>) {
        self.wrappedValue = DependencyValues.shared[keyPath: keyPath]
    }
}
