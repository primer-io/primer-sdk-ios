//
//  DefaultAccessibilityAnnouncementService.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

@available(iOS 15.0, *)
@MainActor
final class DefaultAccessibilityAnnouncementService: AccessibilityAnnouncementService, LogReporter {

  private let publisher: UIAccessibilityNotificationPublisher

  // Default constructed in-body (not as a default arg): the publisher is @MainActor-isolated,
  // and default-argument expressions are evaluated in a nonisolated context.
  init(publisher: UIAccessibilityNotificationPublisher? = nil) {
    self.publisher = publisher ?? DefaultUIAccessibilityNotificationPublisher()
  }

  func announceError(_ message: String) {
    logger.debug(message: "[A11Y] Announcing error: \(message)")
    publisher.post(notification: .announcement, argument: message)
  }

  func announceStateChange(_ message: String) {
    logger.debug(message: "[A11Y] Announcing state change: \(message)")
    publisher.post(notification: .announcement, argument: message)
  }

  func announceLayoutChange(_ message: String) {
    logger.debug(message: "[A11Y] Announcing layout change: \(message)")
    publisher.post(notification: .layoutChanged, argument: message)
  }

  func announceScreenChange(_ message: String) {
    logger.debug(message: "[A11Y] Announcing screen change: \(message)")
    publisher.post(notification: .screenChanged, argument: message)
  }
}
