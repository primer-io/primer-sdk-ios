//
//  MockAnalyticsInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
typealias TrackedEvent = (eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?)

@available(iOS 15.0, *)
actor MockAnalyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol {

    // MARK: - Call Tracking

    private(set) var trackEventCallCount = 0
    private(set) var trackedEvents: [(eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?)] = []

    // MARK: - Protocol Implementation

    func trackEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async {
        trackEventCallCount += 1
        trackedEvents.append((eventType: eventType, metadata: metadata))
    }

    // MARK: - Test Helpers

    func reset() {
        trackEventCallCount = 0
        trackedEvents = []
    }

    func getLastTrackedEvent() -> TrackedEvent? {
        trackedEvents.last
    }

    func hasTrackedEvent(_ eventType: AnalyticsEventType) -> Bool {
        trackedEvents.contains { $0.eventType == eventType }
    }
}
