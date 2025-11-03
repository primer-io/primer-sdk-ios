//
//  DefaultAccessibilityAnnouncementService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

/// Default implementation of AccessibilityAnnouncementService using UIAccessibility.post()
final class DefaultAccessibilityAnnouncementService: AccessibilityAnnouncementService {

    init() {}

    func announceError(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    func announceStateChange(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    func announceLayoutChange(_ message: String) {
        UIAccessibility.post(notification: .layoutChanged, argument: message)
    }

    func announceScreenChange(_ message: String) {
        UIAccessibility.post(notification: .screenChanged, argument: message)
    }
}
