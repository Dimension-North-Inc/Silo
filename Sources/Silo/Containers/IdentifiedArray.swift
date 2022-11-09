//
//  IdentifiedArray.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-11-03.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation
import OrderedCollections

public struct IdentifiedArray<Value: Identifiable>: RandomAccessCollection {
    private var container = OrderedDictionary<Value.ID, Value>()
    
    public init() {
    }
    public init(_ value: Value) {
        append(value)
    }
    public init<C>(_ values: C) where C: Collection, C.Element == Value {
        append(values)
    }
    
    public mutating func append(_ value: Value) {
        container[value.id] = value
    }
    public mutating func append<C>(_ values: C) where C: Collection, C.Element == Value {
        for value in values {
            container[value.id] = value
        }
    }

    public subscript(id: Value.ID) -> Value? {
        container[id]
    }
    
    // MARK: - RandomAccessCollection
    public subscript(position: Int) -> Value {
        container.values[position]
    }
    public var startIndex: Int {
        container.values.startIndex
    }
    public var endIndex: Int {
        container.values.endIndex
    }
}

extension IdentifiedArray: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Value...) {
        self.init(elements)
    }
}
