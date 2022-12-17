//
//  UUID.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-12-03.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

/// A  `UUID` generator
///
/// While testing, either `.constant` or `.sequential` generators
/// can be substituted for the default `.random` generator used.
///
public struct UUIDGenerator: Sendable {
    public static var value: Self =  .random

    private var generate: @Sendable () -> UUID
            
    public func callAsFunction() -> UUID {
      self.generate()
    }

    /// A `UUIDGenerator` which returns a `UUID`
    public static var random: Self {
        Self { UUID() }
    }

    /// A `UUIDGenerator` which returns an incrementing `UUID`
    /// beginning at `00000000-0000-0000-0000-000000000000`,
    /// through to maximum `00000000-0000-0000-0000-FFFFFFFFFFFF`
    public static var sequential: Self {
        final class Impl: @unchecked Sendable {
            var index = 0
            var mutex = Mutex()

            func next() -> UUID {
                mutex.locked {
                    defer { index += 1 }
                    let suffix = String(format: "%012x", index)
                    return UUID(uuidString: "00000000-0000-0000-0000-\(suffix)")!
                }
            }
        }

        let impl = Impl()
        return Self { impl.next() }
    }
    
    /// A `UUIDGenerator` which returns a constant `UUID`
    /// - Parameter now: a constant date
    /// - Returns: a `UUIDGenerator`
    public static func constant(_ uuid: UUID) -> Self {
        Self { uuid }
    }
}

extension Builtins {
    /// an injectable UUID
    public static let uuid = Injectable<UUIDGenerator> { .random }
}
