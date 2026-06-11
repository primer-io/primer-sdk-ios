//
//  UIAccessibilityNotificationPublisher.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
@MainActor
protocol UIAccessibilityNotificationPublisher {
  func post(notification: UIAccessibility.Notification, argument: Any?)
}
