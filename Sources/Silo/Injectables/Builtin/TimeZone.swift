//
//  TimeZone.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-12-04.
//

import Foundation

extension Builtins {
    public static var timeZone = Injectable<TimeZone> { .autoupdatingCurrent }
}
