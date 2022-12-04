//
//  Locale.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-12-04.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

extension DependencyValues {
    /// The current locale
    ///
    /// By default, the locale returned from `Locale.autoupdatingCurrent` is supplied.
    ///
    public var locale: Locale {
        get { self[LocaleKey.self] }
        set { self[LocaleKey.self] = newValue }
    }
    
    private enum LocaleKey: DependencyKey {
        static let defaultValue = Locale.autoupdatingCurrent
    }
}
