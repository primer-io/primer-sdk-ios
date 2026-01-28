//
//  UIAccessibilityNotificationPublisher.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

@available(iOS 15.0, *)
protocol UIAccessibilityNotificationPublisher {
  func post(notification: UIAccessibility.Notification, argument: Any?)
}
