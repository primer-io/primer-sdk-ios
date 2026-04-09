//
//  MockAnalyticsStorage.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

class MockAnalyticsStorage: Analytics.Storage {

    var events: [StoredEvent] = []

    func loadEvents() -> [StoredEvent] {
        events
    }

    func save(_ events: [StoredEvent]) throws {
        self.events = events
    }

    func delete(_ eventsToDelete: [StoredEvent]) {
        let idsToDelete = eventsToDelete.map(\.localId)
        self.events = self.events.filter { event in
            !idsToDelete.contains(event.localId)
        }

    }

    var onDeleteEventsWithUrl: ((URL) -> Void)?

    func delete(eventsWithUrl url: URL) {
        delete(loadEvents().filter { $0.analyticsUrl == url.absoluteString })
        onDeleteEventsWithUrl?(url)
    }

    var onDeleteAnalyticsFile: (() -> Void)?

    func deleteAnalyticsFile() {
        events = []
        onDeleteAnalyticsFile?()
    }
}
