//
//  MockAnalyticsService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK

final class MockAnalyticsService: AnalyticsServiceProtocol {
    private var eventsStorage: [Analytics.Event] = []
    var onRecord: (([Analytics.Event]) -> Void)?

    func record(events: [Analytics.Event]) async throws {
        eventsStorage.append(contentsOf: events)
        onRecord?(events)
    }

    func fire(events: [Analytics.Event]) {
        eventsStorage.append(contentsOf: events)
        onRecord?(events)
    }

    func record(event: Analytics.Event) async throws {
        eventsStorage.append(contentsOf: [event])
        onRecord?([event])
    }

    func fire(event: PrimerSDK.Analytics.Event) {
        eventsStorage.append(contentsOf: [event])
        onRecord?([event])
    }
}
