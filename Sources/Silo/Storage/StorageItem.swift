//
//  SwiftUIView.swift
//  
//
//  Created by Mark Onyschuk on 2022-12-15.
//

import SwiftUI

/// A stored key/value pair
public protocol StorageItem<Value> {
    associatedtype Value: Codable
    
    var key:    String { get }
    var value:  Value  { get nonmutating set }
}
