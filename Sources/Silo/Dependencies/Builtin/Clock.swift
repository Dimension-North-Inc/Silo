//
//  Clock.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-12-03.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Clocks
import Foundation

extension DependencyValues {
    
    /// A continuous clock
    ///
    public var continuousClock: any Clock<Duration> {
        get { self[ContinuousClockKey.self] }
        set { self[ContinuousClockKey.self] = newValue }
    }
    
    /// A suspending clock
    /// 
    public var suspendingClock: any Clock<Duration> {
        get { self[SuspendingClockKey.self] }
        set { self[SuspendingClockKey.self] = newValue }
    }

    private enum ContinuousClockKey: DependencyKey {
        static var defaultValue: any Clock<Duration> = ContinuousClock()
    }
    private enum SuspendingClockKey: DependencyKey {
        static var defaultValue: any Clock<Duration> = SuspendingClock()
    }
}
