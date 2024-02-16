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

    var storage: MockAnalyticsStorage!

    var service: Analytics.Service!

    override func setUp() {
        apiClient = MockPrimerAPIAnalyticsClient()
        storage = MockAnalyticsStorage()
        service = Analytics.Service(sdkLogsUrl: URL(string: "http://localhost/")!,
                                    batchSize: 5,
                                    storage: storage,
                                    apiClient: apiClient)
    }

    override func tearDown() {
        service = nil
        storage = nil
        apiClient = nil

        PrimerAPIConfigurationModule.clientToken = nil
    }

    func testSimpleMessageEventBatchSend() throws {

        // Setup API Client

        let expectation = self.expectation(description: "Batch of five events are sent")

        apiClient.onSendAnalyticsEvent = { events in
            XCTAssertNotNil(events)
            XCTAssertEqual(events?.count, 5)

            let messages = events!.enumerated().compactMap { (_, event) in
                return (event.properties as? MessageEventProperties)?.message
            }.sorted()
            XCTAssertEqual(messages, ["Test #1", "Test #2", "Test #3", "Test #4", "Test #5"])
            expectation.fulfill()
        }

        // Send Events

        let expectation2 = self.expectation(description: "Wait for all events to be sent")
        _ = sendEvents(numberOfEvents: 5).ensure {
            expectation2.fulfill()
        }

        waitForExpectations(timeout: 30.0)
    }

    func testSimpleSDKEventBatchSend() throws {

        // Setup API Client

        let expectation = self.expectation(description: "Batch of five events are sent")

        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken

        apiClient.onSendAnalyticsEvent = { events in
            XCTAssertNotNil(events)
            XCTAssertEqual(events?.count, 5)

            let messages = events!.enumerated().compactMap { (_, event) in
                return (event.properties as? SDKEventProperties)?.name
            }.sorted()
            XCTAssertEqual(messages, ["Test #1", "Test #2", "Test #3", "Test #4", "Test #5"])
            expectation.fulfill()
        }

        // Send Events

        let expectation2 = self.expectation(description: "Wait for all events to be sent")
        _ = sendEvents(numberOfEvents: 5, eventType: .sdkEvent).ensure {
            expectation2.fulfill()
        }
        waitForExpectations(timeout: 30.0)
    }

    func testComplexMultiBatchFastSend() throws {

        let expectation = self.expectation(description: "Called expected number of times")
        expectation.expectedFulfillmentCount = 5

        apiClient.onSendAnalyticsEvent = { _ in
            expectation.fulfill()
        }

        var promises: [Promise<Void>] = []
        (0..<5).forEach { _ in
            promises.append(sendEvents(numberOfEvents: 5, after: 0.1))
        }
        promises.append(sendEvents(numberOfEvents: 4, after: 0.5))

        let expectation2 = self.expectation(description: "Wait for all events to be sent")
        _ = when(fulfilled: promises).ensure {
            expectation2.fulfill()
        }
        waitForExpectations(timeout: 60.0)

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

        var promises: [Promise<Void>] = []
        (0..<3).forEach { _ in
            promises.append(sendEvents(numberOfEvents: 5, after: 0.5))
        }
        promises.append(sendEvents(numberOfEvents: 4, after: 0.5))

        let expectation2 = self.expectation(description: "Wait for all events to be sent")
        _ = when(fulfilled: promises).ensure {
            expectation2.fulfill()
        }
        waitForExpectations(timeout: 30.0)

        XCTAssertEqual(apiClient.batches.count, 3)
        XCTAssertEqual(apiClient.batches.joined().count, 15)
        XCTAssertEqual(storage.loadEvents().count, 4)
    }

    func testFlush() throws {

        let flushExpectation = self.expectation(description: "All events flushed")
        firstly {
            sendEvents(numberOfEvents: 4, after: 0.5)
        }.then {
            self.service.flush()
        }.done { _ in
            flushExpectation.fulfill()
        }.catch { err in
            XCTFail("Failed to successfully flush - error message: \(err)")
        }

        waitForExpectations(timeout: 10.0)

        XCTAssertEqual(apiClient.batches.count, 1)
        XCTAssertEqual(apiClient.batches.joined().count, 4)
        XCTAssertEqual(storage.loadEvents().count, 0)
    }

    func testSendFailureDeleteSdkEvents() throws {
        SDKSessionHelper.setUp()
        defer { SDKSessionHelper.tearDown() }

        apiClient.shouldSucceed = false

        let expectation = self.expectation(description: "Wait for all events to be sent")
        _ = sendEvents(numberOfEvents: 4, eventType: .sdkEvent).ensure {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0)

        XCTAssertEqual(storage.events.count, 4)

        let expectation2 = self.expectation(description: "Expect event deletion on failure")
        storage.onDeleteEventsWithUrl = { _ in
            expectation2.fulfill()
        }

        let expectation3 = self.expectation(description: "Wait for all events to be sent")
        _ = sendEvents(numberOfEvents: 4, eventType: .sdkEvent).ensure {
            expectation3.fulfill()
        }
        waitForExpectations(timeout: 10.0)

        XCTAssertEqual(storage.events.count, 0)
    }

    func testSendFailurePurgeAllEvents() {
        SDKSessionHelper.setUp()
        defer { SDKSessionHelper.tearDown() }

        apiClient.shouldSucceed = false

        let expectation2 = self.expectation(description: "Full event purge triggered")
        self.storage.onDeleteAnalyticsFile = {
            expectation2.fulfill()
        }

        let expectation = self.expectation(description: "Did complete")

        _ = firstly {
            self.sendEvents(numberOfEvents: 5, eventType: .sdkEvent)
        }.then {
            self.sendEvents(numberOfEvents: 5, eventType: .sdkEvent)
        }.then {
            self.sendEvents(numberOfEvents: 5, eventType: .sdkEvent)
        }.ensure {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        XCTAssertEqual(storage.loadEvents().count, 0)
    }

    // MARK: Helpers

    static func createQueue() -> DispatchQueue {
        DispatchQueue(label: "AnalyticsServiceTestsQueue-\(UUID().uuidString)", qos: .background, attributes: .concurrent)
    }
    
    @discardableResult
    func sendEvents(numberOfEvents: Int,
                    eventType: Analytics.Event.EventType = .message,
                    after delay: TimeInterval? = nil,
                    onQueue queue: DispatchQueue = AnalyticsServiceTests.createQueue()) -> Promise<Void> {
        let events = (0..<numberOfEvents).compactMap { num in
            switch eventType {
            case .message:
                return messageEvent(withMessage: "Test #\(num + 1)")
            case .sdkEvent:
                return sdkEvent(name: "Test #\(num + 1)")
            default:
                XCTFail()
                return nil
            }
        }
        let promises = events.map { (event: Analytics.Event) in
            Promise { seal in
                let _callback = { [weak self] in
                    _ = self?.service.record(event: event).ensure {
                        seal.fulfill()
                    }
                }
                if let delay = delay {
                    queue.asyncAfter(deadline: .now() + delay, execute: _callback)
                } else {
                    queue.async(execute: _callback)
                }
            }
        }
        return when(fulfilled: promises)
    }

    func messageEvent(withMessage message: String) -> Analytics.Event {
        Analytics.Event.message(
            message: message,
            messageType: .other,
            severity: .info
        )
    }

    func sdkEvent(name: String, params: [String: String]? = nil) -> Analytics.Event {
        Analytics.Event.sdk(
            name: name,
            params: params
        )
    }
}
