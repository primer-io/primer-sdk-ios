//
//  MockAnalyticsStorage.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerCore
@testable import PrimerSDK
import XCTest

final class MockAnalyticsStorage: Analytics.Storage {

    nonisolated(unsafe) var events: [Analytics.Event] = []
    nonisolated(unsafe) var onDeleteEventsWithUrl: ((URL) -> Void)?
    nonisolated(unsafe) var onDeleteAnalyticsFile: (() -> Void)?

    func loadEvents() -> [Analytics.Event] {
        events
    }

    func save(_ events: [Analytics.Event]) throws {
        self.events = events
    }

    func delete(_ eventsToDelete: [Analytics.Event]) {
        let idsToDelete = eventsToDelete.map(\.localId)
        self.events = self.events.filter { event in
            !idsToDelete.contains(event.localId)
        }

    }

    func delete(eventsWithUrl url: URL) {
        delete(loadEvents().filter { $0.analyticsUrl == url.absoluteString })
        onDeleteEventsWithUrl?(url)
    }

    func deleteAnalyticsFile() {
        events = []
        onDeleteAnalyticsFile?()
    }
}
