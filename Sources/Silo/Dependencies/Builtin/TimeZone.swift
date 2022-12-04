//
//  TimeZone.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-12-04.
//

import Foundation

extension DependencyValues {
    /// The current time zone to use while handling dates
    ///
    /// By default, the time zone returned from `TimeZone.autoupdatingCurrent` is supplied.
    ///
    public var timeZone: TimeZone {
        get { self[TimeZoneKey.self] }
        set { self[TimeZoneKey.self] = newValue }
    }
    
    private enum TimeZoneKey: DependencyKey {
        static let defaultValue = TimeZone.autoupdatingCurrent
    }
}
