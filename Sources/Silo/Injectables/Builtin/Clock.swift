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
    public static var continuousClock: Factory<any Clock<Duration>> = Factory(ContinuousClock())
    public static var suspendingClock: Factory<any Clock<Duration>> = Factory(SuspendingClock())
}
