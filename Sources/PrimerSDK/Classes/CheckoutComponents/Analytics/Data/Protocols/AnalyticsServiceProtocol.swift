//
//  AnalyticsServiceProtocol.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol CheckoutComponentsAnalyticsServiceProtocol: Actor {
    func initialize(config: AnalyticsSessionConfig) async
    func sendEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async
}
