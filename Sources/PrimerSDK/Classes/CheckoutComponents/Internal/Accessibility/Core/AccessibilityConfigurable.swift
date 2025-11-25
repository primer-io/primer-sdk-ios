//
//  AccessibilityConfigurable.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Protocol for components that can apply accessibility configuration
protocol AccessibilityConfigurable {

    /// Apply accessibility metadata to this component
    /// - Parameter config: Configuration containing identifier, label, hint, traits
    func applyAccessibility(_ config: AccessibilityConfiguration)
}
