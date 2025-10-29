//
//  View+Accessibility.swift
//  PrimerSDK
//
//  Created by Claude Code on 2025-10-28.
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
extension View {
    /// Apply accessibility configuration using builder pattern
    /// - Parameter config: Accessibility configuration to apply
    /// - Returns: Modified view with accessibility properties
    func accessibility(_ config: AccessibilityConfiguration) -> some View {
        self
            .accessibilityLabel(config.label)
            .accessibilityHint(config.hint ?? "")
            .accessibilityIdentifier(config.identifier)
            .accessibilityValue(config.value ?? "")
            .accessibilityAddTraits(config.traits)
    }

    /// Apply individual accessibility properties
    /// - Parameters:
    ///   - label: Accessibility label
    ///   - hint: Optional accessibility hint
    ///   - identifier: Accessibility identifier for UI testing
    ///   - traits: Accessibility traits
    ///   - value: Optional accessibility value
    /// - Returns: Modified view with accessibility properties
    func accessibility(
        label: String,
        hint: String? = nil,
        identifier: String,
        traits: UIAccessibilityTraits = .none,
        value: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityIdentifier(identifier)
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
    }
}
