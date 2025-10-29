//
//  AccessibilityConfiguration.swift
//  PrimerSDK
//
//  Created by Claude Code on 2025-10-28.
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
/// Value type encapsulating all accessibility properties for a UI component
struct AccessibilityConfiguration {
    /// Unique accessibility identifier for UI testing
    let identifier: String

    /// Localized human-readable description of the element
    let label: String

    /// Optional localized interaction guidance
    let hint: String?

    /// Semantic role indicators
    let traits: UIAccessibilityTraits

    /// Optional current state for dynamic elements
    let value: String?

    /// Initialize accessibility configuration
    /// - Parameters:
    ///   - identifier: Unique identifier for UI testing (must be non-empty, alphanumeric with underscores)
    ///   - label: Localized description (must be non-empty)
    ///   - hint: Optional interaction hint
    ///   - traits: Semantic role traits
    ///   - value: Optional current state value
    init(
        identifier: String,
        label: String,
        hint: String? = nil,
        traits: UIAccessibilityTraits = .none,
        value: String? = nil
    ) {
        self.identifier = identifier
        self.label = label
        self.hint = hint
        self.traits = traits
        self.value = value
    }
}

@available(iOS 15.0, *)
/// Types of VoiceOver announcements
enum AccessibilityAnnouncementType {
    /// Major navigation change
    case screenChanged(focusElement: Any?)

    /// Dynamic content update
    case layoutChanged(focusElement: Any?)

    /// Non-disruptive message
    case announcement(message: String)

    /// Post announcement to VoiceOver
    func post() {
        switch self {
        case let .screenChanged(element):
            UIAccessibility.post(notification: .screenChanged, argument: element)
        case let .layoutChanged(element):
            UIAccessibility.post(notification: .layoutChanged, argument: element)
        case let .announcement(message):
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
}
