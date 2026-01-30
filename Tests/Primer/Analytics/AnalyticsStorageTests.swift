//
//  AnalyticsStorageTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerCore
@testable import PrimerSDK
import XCTest

final class AnalyticsStorageTests: XCTestCase {

    var storage: Analytics.Storage!

    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("analytics")

    let events = [
        Analytics.Event.message(message: "Test #1", messageType: .other, severity: .info),
        Analytics.Event.message(message: "Test #2", messageType: .other, severity: .info),
        Analytics.Event.message(message: "Test #3", messageType: .other, severity: .info)
    ]

    override func setUpWithError() throws {
        storage = Analytics.DefaultStorage(fileURL: url)
    }

    override func tearDownWithError() throws {
        storage = nil
    }

    func testSaveLoadDelete() throws {
        try storage.save(events)

        let loadedEvents = storage.loadEvents()
        XCTAssertEqual(Set(events), Set(loadedEvents))

        storage.delete(events)

        let reloadedEvents = storage.loadEvents()

        XCTAssert(reloadedEvents.isEmpty)
    }

    func testDeleteFile() throws {
        try storage.save(events)

        let loadedEvents = storage.loadEvents()
        XCTAssertEqual(Set(events), Set(loadedEvents))

        XCTAssert(FileManager.default.fileExists(atPath: url.path))

        storage.deleteAnalyticsFile()

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testDeleteEvents() throws {
        try storage.save(events)

        let loadedEvents = storage.loadEvents()
        XCTAssertEqual(Set(events), Set(loadedEvents))

        storage.delete([events[0]])

        let reloadedEvents = storage.loadEvents()
        XCTAssertEqual(Set(events[1...]), Set(reloadedEvents))
    }

    func testLoadNoFile() throws {
        storage.deleteAnalyticsFile()
        let events = storage.loadEvents()
        XCTAssertEqual(events, [])
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testLoadCorruptFileAndAutoDelete() throws {
        FileManager.default.createFile(atPath: url.path, contents: "abc123".data(using: .utf8))
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        let events = storage.loadEvents()

        XCTAssertEqual(events, [])
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testSaveInvalidFileLocation() throws {
        storage = Analytics.DefaultStorage(fileURL: URL(string: "file:///not_valid")!)

        do {
            try storage.save(events)
            XCTFail()
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

extension Analytics.Event: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(localId)
    }
}
