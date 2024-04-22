//
//  MockAnalyticsStorage.swift
//  Debug App
//
//  Created by Jack Newcombe on 13/02/2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class MockAnalyticsStorage: Analytics.Storage {

    var events: [Analytics.Event] = []

    func loadEvents() -> [Analytics.Event] {
        return events
    }

    func save(_ events: [Analytics.Event]) throws {
        self.events = events
    }

    func delete(_ eventsToDelete: [Analytics.Event]) {
        let idsToDelete = eventsToDelete.map { $0.localId }
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
