//
//  MockAnalyticsService.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK

final actor MockAnalyticsService: AnalyticsServiceProtocol {
    private var eventsStorage: [any AnalyticsEvent] = []
    nonisolated(unsafe) var onRecord: (([any AnalyticsEvent]) -> Void)?

    func record(events: [any AnalyticsEvent]) async throws {
        eventsStorage.append(contentsOf: events)
        onRecord?(events)
    }

    func fire(events: [any AnalyticsEvent]) {
        eventsStorage.append(contentsOf: events)
        onRecord?(events)
    }

    func record(event: any AnalyticsEvent) async throws {
        eventsStorage.append(contentsOf: [event])
        onRecord?([event])
    }

    func fire(event: any AnalyticsEvent) {
        eventsStorage.append(contentsOf: [event])
        onRecord?([event])
    }
}
