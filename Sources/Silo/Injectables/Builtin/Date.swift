//
//  Date.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-12-03.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation


/// A  `Date` generator
///
/// While testing, a `.constant` generator can be substituted for the default `.now` generator used.
///
public struct DateGenerator: Sendable {
    private var generate: @Sendable () -> Date
            
    public func callAsFunction() -> Date {
      self.generate()
    }

    public var now: Date {
        generate()
    }

    /// A `DateGenerator` which returns the current `Date`
    public static var current: Self {
        Self { Date() }
    }
    
    /// A `DateGenerator` which returns a constant `Date`
    /// - Parameter now: a constant date
    /// - Returns: a `DateGenerator`
    public static func constant(_ now: Date) -> Self {
        Self { now }
    }
}

extension Builtins {
    /// an injectable date
    public static var date = Injectable<DateGenerator> { .current }
}
