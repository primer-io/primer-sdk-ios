//
//  MockTrackingAnalyticsInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
actor MockTrackingAnalyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol {

    // MARK: - Call Tracking

    private(set) var trackedEvents: [(eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?)] = []

    var trackEventCallCount: Int { trackedEvents.count }

    private(set) var recordedThreeDSOutcomes: [AnalyticsFunnelState.ThreeDSOutcome] = []

    // MARK: - CheckoutComponentsAnalyticsInteractorProtocol

    func trackEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async {
        trackedEvents.append((eventType: eventType, metadata: metadata))
    }

    func recordThreeDSOutcome(_ outcome: AnalyticsFunnelState.ThreeDSOutcome) async {
        recordedThreeDSOutcomes.append(outcome)
    }

    // MARK: - Test Helpers

    func hasTracked(_ eventType: AnalyticsEventType) -> Bool {
        trackedEvents.contains { $0.eventType == eventType }
    }

    func reset() {
        trackedEvents.removeAll()
    }
}
