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

    func testSimpleMessageEventBatchSend_async() async throws {
        // Set up expectation for batch of five events being sent
        let batchSentExpectation = expectation(description: "Batch of five events is sent")

        // Mock API client behavior to validate the events sent
        apiClient.onSendAnalyticsEvent = { events in
            XCTAssertNotNil(events, "Expected events to be non-nil")
            XCTAssertEqual(events?.count, 5, "Expected exactly 5 events to be sent")

            let messages = events!.compactMap { event in
                (event.properties as? MessageEventProperties)?.message
            }.sorted()

            XCTAssertEqual(
                messages,
                ["Test #1", "Test #2", "Test #3", "Test #4", "Test #5"],
                "Expected messages to match the test data"
            )
            batchSentExpectation.fulfill()
        }

        // Send 5 events asynchronously
        try await sendEvents(numberOfEvents: 5)

        // Wait for the expectation to be fulfilled
        await fulfillment(of: [batchSentExpectation], timeout: 30.0)
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

    func testSimpleSDKEventBatchSend_async() async throws {
        // Set up expectation for batch of five events being sent
        let batchSentExpectation = expectation(description: "Batch of five SDK events is sent")

        // Set a mock client token for SDK events
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken

        // Mock API client behavior to validate the events sent
        apiClient.onSendAnalyticsEvent = { events in
            XCTAssertNotNil(events, "Expected events to be non-nil")
            XCTAssertEqual(events?.count, 5, "Expected exactly 5 events to be sent")

            let messages = events!.compactMap { event in
                (event.properties as? SDKEventProperties)?.name
            }.sorted()

            XCTAssertEqual(
                messages,
                ["Test #1", "Test #2", "Test #3", "Test #4", "Test #5"],
                "Expected SDK event names to match the test data"
            )
            batchSentExpectation.fulfill()
        }

        // Send 5 SDK events asynchronously
        try await sendEvents(numberOfEvents: 5, eventType: .sdkEvent)

        // Wait for the expectation to be fulfilled
        await fulfillment(of: [batchSentExpectation], timeout: 30.0)
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
    
    func testComplexMultiBatchFastSend_async() async throws {
        // Set up expectation for the number of batches sent
        let batchSentExpectation = expectation(description: "Expected number of batches sent")
        batchSentExpectation.expectedFulfillmentCount = 5

        // Mock API client behavior to fulfill the expectation for each batch sent
        apiClient.onSendAnalyticsEvent = { _ in
            batchSentExpectation.fulfill()
        }

        // Create tasks to send events in batches
        var tasks: [Task<Void, Error>] = []
        for _ in 0 ..< 5 {
            tasks.append(Task {
                try await self.sendEvents(numberOfEvents: 5, after: 0.1)
            })
        }
        tasks.append(Task {
            try await self.sendEvents(numberOfEvents: 4, after: 0.5)
        })

        // Set up an expectation to wait for all tasks to complete
        let allTasksCompletedExpectation = expectation(description: "All tasks completed")
        Task {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for task in tasks {
                    group.addTask {
                        try await task.value
                    }
                }
                try await group.waitForAll()
            }
            allTasksCompletedExpectation.fulfill()
        }

        // Wait for all expectations to be fulfilled
        await fulfillment(of: [batchSentExpectation, allTasksCompletedExpectation], timeout: 60.0)

        // Verify the number of batches and events sent
        XCTAssertEqual(apiClient.batches.count, 5, "Expected 5 batches to be sent")
        XCTAssertEqual(apiClient.batches.joined().count, 25, "Expected 25 events to be sent in total")
        XCTAssertEqual(storage.loadEvents().count, 4, "Expected 4 events to remain in storage")
    }
    
    func testComplexMultiBatchSlowSend() throws {

        let expectation = self.expectation(description: "Events sent to API client expected number of times")
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

    func testComplexMultiBatchSlowSend_async() async throws {
        // Set up expectation for the number of batches sent
        let batchSentExpectation = expectation(description: "Events sent to API client expected number of times")
        batchSentExpectation.expectedFulfillmentCount = 3

        // Mock API client behavior to fulfill the expectation for each batch sent
        apiClient.onSendAnalyticsEvent = { _ in
            batchSentExpectation.fulfill()
        }

        // Create tasks to send events in batches
        var tasks: [Task<Void, Error>] = []
        for _ in 0 ..< 3 {
            tasks.append(Task {
                try await self.sendEvents(numberOfEvents: 5, after: 0.5)
            })
        }
        tasks.append(Task {
            try await self.sendEvents(numberOfEvents: 4, after: 0.5)
        })

        // Set up an expectation to wait for all tasks to complete
        let allTasksCompletedExpectation = expectation(description: "All tasks completed")
        Task {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for task in tasks {
                    group.addTask {
                        try await task.value
                    }
                }
                try await group.waitForAll()
            }
            allTasksCompletedExpectation.fulfill()
        }

        // Wait for all expectations to be fulfilled
        await fulfillment(of: [batchSentExpectation, allTasksCompletedExpectation], timeout: 30.0)

        // Verify the number of batches and events sent
        XCTAssertEqual(apiClient.batches.count, 3, "Expected 3 batches to be sent")
        XCTAssertEqual(apiClient.batches.joined().count, 15, "Expected 15 events to be sent in total")
        XCTAssertEqual(storage.loadEvents().count, 4, "Expected 4 events to remain in storage")
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
    
    func testFlush_async() async throws {
        // Set up expectation for all events to be flushed
        let flushExpectation = expectation(description: "All events flushed")

        // Send 4 events asynchronously with a delay
        try await sendEvents(numberOfEvents: 4, after: 0.5)

        // Flush the service to send all stored events
        try await service.flush()
        flushExpectation.fulfill()

        // Wait for the expectation to be fulfilled
        await fulfillment(of: [flushExpectation], timeout: 10.0)

        // Verify all events were sent and storage is empty
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
        _ = sendEvents(numberOfEvents: 1, eventType: .sdkEvent).ensure {
            expectation3.fulfill()
        }
        waitForExpectations(timeout: 10.0)

        XCTAssertEqual(storage.events.count, 0)
    }

    func testSendFailureDeleteSdkEvents_async() async throws {
        // Set up the test environment
        SDKSessionHelper.setUp()
        defer { SDKSessionHelper.tearDown() }

        // Simulate API client failure
        apiClient.shouldSucceed = false

        // Step 1: Attempt to send 4 events and verify they are stored
        do {
            try await sendEvents(numberOfEvents: 4, eventType: .sdkEvent)
        } catch {
            XCTFail("Unexpected failure while sending events: \(error)")
        }
        XCTAssertEqual(storage.events.count, 4, "Expected 4 events to be stored after failure.")

        // Step 2: Set up expectation for event deletion on failure
        let deletionExpectation = expectation(description: "Event deletion triggered on failure")
        storage.onDeleteEventsWithUrl = { _ in
            deletionExpectation.fulfill()
        }

        // Step 3: Attempt to send 1 event and verify it triggers deletion
        do {
            try await sendEvents(numberOfEvents: 1, eventType: .sdkEvent)
        } catch {
            XCTFail("Unexpected failure while sending events: \(error)")
        }

        // Step 4: Wait for the deletion expectation to be fulfilled
        await fulfillment(of: [deletionExpectation], timeout: 10.0)

        // Step 5: Verify all events have been deleted
        XCTAssertEqual(storage.events.count, 0, "Expected all events to be deleted after failure.")
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

    func testSendFailurePurgeAllEvents_async() async {
        // Set up the test environment
        SDKSessionHelper.setUp()
        defer { SDKSessionHelper.tearDown() }

        // Simulate API client failure
        apiClient.shouldSucceed = false

        // Set up expectation for full event purge
        let purgeExpectation = expectation(description: "Full event purge triggered")
        storage.onDeleteAnalyticsFile = {
            purgeExpectation.fulfill()
        }

        // Step 1: Send 3 batches of 5 sdkEvents each
        do {
            try await sendEvents(numberOfEvents: 5, eventType: .sdkEvent)
            try await sendEvents(numberOfEvents: 5, eventType: .sdkEvent)
            try await sendEvents(numberOfEvents: 5, eventType: .sdkEvent)
        } catch {
            XCTFail("Unexpected failure while sending events: \(error)")
        }

        // Step 2: Wait for the purge expectation to be fulfilled
        await fulfillment(of: [purgeExpectation], timeout: 10.0)

        // Step 3: Verify all events have been purged
        XCTAssertEqual(storage.loadEvents().count, 0, "Expected all events to be purged after failures.")
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
