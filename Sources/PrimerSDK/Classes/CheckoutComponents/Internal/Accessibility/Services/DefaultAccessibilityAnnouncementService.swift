//
//  DefaultAccessibilityAnnouncementService.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

@available(iOS 15.0, *)
final class DefaultAccessibilityAnnouncementService: AccessibilityAnnouncementService, LogReporter {

  // MARK: - Properties

  private let publisher: UIAccessibilityNotificationPublisher

  // MARK: - Initialization

  init(
    publisher: UIAccessibilityNotificationPublisher = DefaultUIAccessibilityNotificationPublisher()
  ) {
    self.publisher = publisher
  }

  // MARK: - AccessibilityAnnouncementService

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
