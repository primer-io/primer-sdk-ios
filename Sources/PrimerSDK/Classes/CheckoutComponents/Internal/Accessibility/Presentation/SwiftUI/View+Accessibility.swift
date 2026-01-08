//
//  View+Accessibility.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
extension View {

    /// Applies comprehensive accessibility configuration to a SwiftUI view
    /// - Parameter config: AccessibilityConfiguration containing all accessibility metadata
    /// - Returns: Modified view with accessibility properties applied
    ///
    /// Example usage:
    /// ```swift
    /// Button("Submit") { }
    ///     .accessibility(config: AccessibilityConfiguration(
    ///         identifier: "checkout_submit_button",
    ///         label: "Submit payment",
    ///         hint: "Double-tap to submit payment",
    ///         traits: [.isButton]
    ///     ))
    /// ```
    func accessibility(config: AccessibilityConfiguration) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier(config.identifier)
            .accessibilityLabel(config.label)
            .modifier(ConditionalAccessibilityHint(hint: config.hint))
            .modifier(ConditionalAccessibilityValue(value: config.value))
            .accessibilityAddTraits(config.traits)
            .accessibilityHidden(config.isHidden)
            .accessibilitySortPriority(Double(config.sortPriority))
    }
}

// MARK: - Private Helper Modifiers

/// Conditionally applies accessibility hint only if non-nil and non-empty
@available(iOS 15.0, *)
private struct ConditionalAccessibilityHint: ViewModifier {
    let hint: String?

    func body(content: Content) -> some View {
        if let hint = hint, !hint.isEmpty {
            content.accessibilityHint(hint)
        } else {
            content
        }
    }
}

/// Conditionally applies accessibility value only if non-nil and non-empty
@available(iOS 15.0, *)
private struct ConditionalAccessibilityValue: ViewModifier {
    let value: String?

    func body(content: Content) -> some View {
        if let value = value, !value.isEmpty {
            content.accessibilityValue(value)
        } else {
            content
        }
    }
}
