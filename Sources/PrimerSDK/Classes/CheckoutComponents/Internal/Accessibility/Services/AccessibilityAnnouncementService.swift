//
//  AccessibilityAnnouncementService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Service for posting VoiceOver announcements
///
/// Wraps UIAccessibility.post() with semantic methods that indicate intent and timing requirements.
/// All methods are safe to call even when VoiceOver is disabled.
protocol AccessibilityAnnouncementService {

    /// Announce validation error to VoiceOver user
    ///
    /// **Timing requirement**: <500ms from error detection (FR-023)
    /// **Notification type**: `.announcement` (interrupts current speech)
    ///
    /// - Parameter message: Localized error message
    func announceError(_ message: String)

    /// Announce state change to VoiceOver user
    ///
    /// Examples: "Loading", "Payment processing", "Card selected"
    /// **Notification type**: `.announcement` (interrupts current speech)
    ///
    /// - Parameter message: Localized state change message
    func announceStateChange(_ message: String)

    /// Announce layout change to VoiceOver user
    ///
    /// Examples: "Billing address fields shown", "Additional options available"
    /// **Notification type**: `.layoutChanged` (non-interrupting)
    ///
    /// - Parameter message: Localized layout change message
    func announceLayoutChange(_ message: String)

    /// Announce screen change to VoiceOver user
    ///
    /// Examples: "Payment method selection", "Card form"
    /// **Notification type**: `.screenChanged` (provides full context re-orientation)
    ///
    /// - Parameter message: Localized screen title/description
    func announceScreenChange(_ message: String)
}
