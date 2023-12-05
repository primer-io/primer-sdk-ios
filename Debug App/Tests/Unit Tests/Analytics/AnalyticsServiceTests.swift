//
//  AnalyticsServiceTests.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 04/12/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

final class AnalyticsServiceTests: XCTestCase {
    
    var apiClient: MockPrimerAPIAnalyticsClient!

    var storage: Analytics.Storage!
    
    var service: Analytics.Service!
    
    override func setUpWithError() throws {
        apiClient = MockPrimerAPIAnalyticsClient()
        storage = MockAnalyticsStorage()
        service = Analytics.Service(sdkLogsUrl: URL(string: "http://localhost/")!, 
                                    batchSize: 5,
                                    storage: storage,
                                    apiClient: apiClient)
    }

    override func tearDownWithError() throws {
        service = nil
        storage = nil
        apiClient = nil
    }

    func testSimpleBatchSend() throws {
        
        // Setup API Client
        
        let expectation = self.expectation(description: "Batch of five events are sent")
        
        apiClient.onSendAnalyticsEvent = { events in
            XCTAssertNotNil(events)
            XCTAssertEqual(events?.count, 5)
             
            let messages = events!.enumerated().compactMap { (index, event) in
                return (event.properties as? MessageEventProperties)?.message
            }.sorted()
            XCTAssertEqual(messages, ["Test #1", "Test #2", "Test #3", "Test #4", "Test #5"])
            expectation.fulfill()
        }
        
        // Send Events
        
        sendEvents(numberOfEvents: 5)
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testComplexMultiBatchFastSend() throws {
        
        let expectation = self.expectation(description: "Called expected number of times")
        expectation.expectedFulfillmentCount = 5

        apiClient.onSendAnalyticsEvent = { _ in
            expectation.fulfill()
        }
        
        (0..<5).forEach { _ in
            sendEvents(numberOfEvents: 5, delay: 0.1)
        }
        let expectRemainingEvents = self.expectation(description: "Remaining events are recorded")
        expectRemainingEvents.expectedFulfillmentCount = 4
        sendEvents(numberOfEvents: 4, delay: 0.5) {
            expectRemainingEvents.fulfill()
        }

        waitForExpectations(timeout: 15.0)
        
        XCTAssertEqual(apiClient.batches.count, 5)
        XCTAssertEqual(apiClient.batches.joined().count, 25)
        XCTAssertEqual(storage.loadEvents().count, 4)
    }
    
    func testComplexMultiBatchSlowSend() throws {
        
        let expectation = self.expectation(description: "Called expected number of times")
        expectation.expectedFulfillmentCount = 3
        
        apiClient.onSendAnalyticsEvent = { _ in
            expectation.fulfill()
        }
        
        (0..<3).forEach { _ in
            sendEvents(numberOfEvents: 5, delay: 0.5)
        }
        sendEvents(numberOfEvents: 4, delay: 0.5)
        
        waitForExpectations(timeout: 15.0)
        
        XCTAssertEqual(apiClient.batches.count, 3)
        XCTAssertEqual(apiClient.batches.joined().count, 15)
        XCTAssertEqual(storage.loadEvents().count, 4)
    }
    
    // MARK: Helpers
    
    static func createQueue() -> DispatchQueue {
        DispatchQueue(label: "AnalyticsServiceTestsQueue-\(UUID().uuidString)", qos: .background, attributes: .concurrent)
    }
    
    func sendEvents(numberOfEvents: Int,
                    delay: TimeInterval? = nil,
                    onQueue queue: DispatchQueue = AnalyticsServiceTests.createQueue(),
                    callback: @escaping () -> Void = {}) {
        let events = (0..<numberOfEvents).map { num in messageEvent(withMessage: "Test #\(num + 1)") }
        
        print(">>>>> About to report \(events.count) events")


        events.forEach { (event: Analytics.Event) in
            let expectEventToRecord = self.expectation(description: "event is recorded - \(event.localId)")
            let _callback = {
                print(">>>>> Reporting event on queue")
                _ = self.service.record(event: event).ensure {
                    expectEventToRecord.fulfill()
                    callback()
                }
            }
            if let delay = delay {
                queue.asyncAfter(deadline: .now() + delay, execute: _callback)
            } else {
                queue.async(execute: _callback)
            }
        }
    }
    
    func messageEvent(withMessage message: String) -> Analytics.Event {
        Analytics.Event(eventType: .message, properties: MessageEventProperties(message: message, messageType: .other, severity: .info))
    }
}

class MockAnalyticsStorage: Analytics.Storage {
    
    var events: [Analytics.Event] = []
    
    func loadEvents() -> [Analytics.Event] {
        return events
    }
    
    func save(_ events: [Analytics.Event]) throws {
        self.events = events
    }
    
    func delete(_ eventsToDelete: [Analytics.Event]?) {
        guard let eventsToDelete = eventsToDelete else { return }
        let idsToDelete = eventsToDelete.map { $0.localId }
        print(">>>> Delete events (before): \(self.events.count)")
        self.events = self.events.filter { event in
            !idsToDelete.contains(event.localId)
        }
        
        print(">>>> Delete events (after): \(self.events.count)")
    }
    
    func deleteAnalyticsFile() {
        events = []
    }
}

class MockPrimerAPIAnalyticsClient: PrimerAPIClientAnalyticsProtocol {
    
    var shouldSucceed: Bool = true
    
    var onSendAnalyticsEvent: (([PrimerSDK.Analytics.Event]?) -> Void)?
    
    var batches: [[Analytics.Event]] = []
    
    func sendAnalyticsEvents(clientToken: DecodedJWTToken?, url: URL, body: [Analytics.Event]?, completion: @escaping ResponseHandler) {
        guard let body = body else {
            XCTFail(); return
        }
        print(">>>>> Received batch of: \(body.count)")
        batches.append(body)
        if shouldSucceed {
            completion(.success(.init(id: nil, result: nil)))
        } else {
            completion(.failure(PrimerError.generic(message: "", userInfo: nil, diagnosticsId: "")))
        }
        self.onSendAnalyticsEvent?(body)
    }
}
