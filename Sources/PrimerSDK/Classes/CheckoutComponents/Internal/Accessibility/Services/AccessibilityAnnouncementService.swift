//
//  AccessibilityAnnouncementService.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Wraps UIAccessibility.post() with semantic methods that indicate intent and timing requirements.
protocol AccessibilityAnnouncementService {

  /// **Notification type**: `.announcement` (interrupts current speech)
  func announceError(_ message: String)

  /// Examples: "Loading", "Payment processing", "Card selected"
  /// **Notification type**: `.announcement` (interrupts current speech)
  func announceStateChange(_ message: String)

  /// Examples: "Billing address fields shown", "Additional options available"
  /// **Notification type**: `.layoutChanged` (non-interrupting)
  func announceLayoutChange(_ message: String)

  /// Examples: "Payment method selection", "Card form"
  /// **Notification type**: `.screenChanged` (provides full context re-orientation)
  func announceScreenChange(_ message: String)
}
