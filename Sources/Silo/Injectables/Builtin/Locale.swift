//
//  Locale.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-12-04.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

extension Builtins {
    /// an injectable locale
    public static var locale = Injectable<Locale> { .autoupdatingCurrent }
}
