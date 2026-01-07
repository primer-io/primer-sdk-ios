//
//  MockUIAccessibilityNotificationPublisher.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit
@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockUIAccessibilityNotificationPublisher: UIAccessibilityNotificationPublisher {

    // MARK: - Captured State

    private(set) var postCallCount = 0
    private(set) var lastNotificationType: UIAccessibility.Notification?
    private(set) var lastMessage: String?
    private(set) var allNotifications: [(notification: UIAccessibility.Notification, message: String?)] = []

    // MARK: - UIAccessibilityNotificationPublisher

    func post(notification: UIAccessibility.Notification, argument: Any?) {
        postCallCount += 1
        lastNotificationType = notification
        lastMessage = argument as? String
        allNotifications.append((notification: notification, message: argument as? String))
    }

    // MARK: - Test Helpers

    func reset() {
        postCallCount = 0
        lastNotificationType = nil
        lastMessage = nil
        allNotifications.removeAll()
    }
}
