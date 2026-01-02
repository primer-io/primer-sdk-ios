//
//  DefaultAccessibilityAnnouncementService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

final class DefaultAccessibilityAnnouncementService: AccessibilityAnnouncementService, LogReporter {

    func announceError(_ message: String) {
        logger.debug(message: "[A11Y] Announcing error: \(message)")
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    func announceStateChange(_ message: String) {
        logger.debug(message: "[A11Y] Announcing state change: \(message)")
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    func announceLayoutChange(_ message: String) {
        logger.debug(message: "[A11Y] Announcing layout change: \(message)")
        UIAccessibility.post(notification: .layoutChanged, argument: message)
    }

    func announceScreenChange(_ message: String) {
        logger.debug(message: "[A11Y] Announcing screen change: \(message)")
        UIAccessibility.post(notification: .screenChanged, argument: message)
    }
}
