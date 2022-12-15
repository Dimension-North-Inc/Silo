//
//  Clock.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-12-03.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Clocks
import Foundation

extension Builtins {
    public static var continuousClock = Injectable<any Clock<Duration>> { ContinuousClock() }
    public static var suspendingClock = Injectable<any Clock<Duration>> { SuspendingClock() }
}
