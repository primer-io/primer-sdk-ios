//
//  AccessibilityIdentifierProviding.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Protocol for entities that provide their accessibility identifier
protocol AccessibilityIdentifierProviding {

    /// Unique accessibility identifier for automated testing
    var accessibilityIdentifier: String { get }
}
