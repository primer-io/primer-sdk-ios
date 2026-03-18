//
//  AnalyticsInteractorProtocol.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Fire-and-forget analytics tracking via detached tasks
protocol CheckoutComponentsAnalyticsInteractorProtocol: Actor {
  func trackEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async
}
