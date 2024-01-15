//
//  AnalyticsStorageTests.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 04/12/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

final class AnalyticsStorageTests: XCTestCase {

    var storage: Analytics.Storage!
    
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("analytics")
    
    let events = [
        Analytics.Event(eventType: .message, properties: MessageEventProperties(message: "Test #1", messageType: .other, severity: .info)),
        Analytics.Event(eventType: .message, properties: MessageEventProperties(message: "Test #2", messageType: .other, severity: .info)),
        Analytics.Event(eventType: .message, properties: MessageEventProperties(message: "Test #3", messageType: .other, severity: .info)),
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
}

extension Analytics.Event: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(localId)
    }
}
