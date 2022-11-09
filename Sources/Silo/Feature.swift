//
//  Feature.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-11-01.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

/// A reducer of top-level application features.
///
/// Top level application features typically have a well-defined initialization and starting state;
/// both of which are captured in this `Reducer` subtype.
public protocol Feature: Reducer {
    
    /// feature startup
    init()
    
    /// the feature's starting state
    static var initial: State { get }
}
