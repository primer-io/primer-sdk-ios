//
//  AnalyticsServiceTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class AnalyticsServiceTests: XCTestCase {
    var sut: Analytics.Service!
    var apiClient: MockPrimerAPIAnalyticsClient!
    var storage: MockAnalyticsStorage!

    override func setUp() {
        apiClient = MockPrimerAPIAnalyticsClient()
        storage = MockAnalyticsStorage()
        sut = Analytics.Service(sdkLogsUrl: URL(string: "http://localhost/")!,
                                batchSize: 5,
                                storage: storage,
                                apiClient: apiClient)
    }

    override func tearDown() async throws {
        sut = nil
        storage = nil
        apiClient = nil

        PrimerAPIConfigurationModule.clientToken = nil
    }

    func testSimpleMessageEventBatchSend() async throws {
        let expectation = self.expectation(description: "Batch of five events is sent")

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
            expectation.fulfill()
        }

        let expectation2 = self.expectation(description: "Wait for all events to be sent")
        Task {
            try? await sendEvents(numberOfEvents: 5)
            expectation2.fulfill()
        }

        await fulfillment(of: [expectation, expectation2], timeout: 60.0)
    }

    func testSimpleSDKEventBatchSend() async throws {
        let expectation = self.expectation(description: "Batch of five SDK events is sent")

        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken

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
            expectation.fulfill()
        }

        let expectation2 = self.expectation(description: "Wait for all events to be sent")
        Task {
            try? await sendEvents(numberOfEvents: 5, eventType: .sdkEvent)
            expectation2.fulfill()
        }

        await fulfillment(of: [expectation, expectation2], timeout: 60.0)
    }

    func testComplexMultiBatchFastSend() async throws {
        let expectation = self.expectation(description: "Expected number of batches sent")
        expectation.expectedFulfillmentCount = 5

        apiClient.onSendAnalyticsEvent = { _ in
            expectation.fulfill()
        }

        let expectation2 = self.expectation(description: "Wait for all tasks to complete")

        Task {
            await withTaskGroup(of: Void.self) { group in
                for _ in 0 ..< 5 {
                    group.addTask { try? await self.sendEvents(numberOfEvents: 5, after: 0.1) }
                }
                group.addTask { try? await self.sendEvents(numberOfEvents: 4, after: 0.5) }

                await group.waitForAll()
            }
            expectation2.fulfill()
        }

        await fulfillment(of: [expectation, expectation2], timeout: 60.0)

        XCTAssertEqual(apiClient.batches.count, 5, "Expected 5 batches to be sent")
        XCTAssertEqual(apiClient.batches.joined().count, 25, "Expected 25 events to be sent in total")
        XCTAssertEqual(storage.loadEvents().count, 4, "Expected 4 events to remain in storage")
    }

    func testComplexMultiBatchSlowSend() async throws {
        let expectation = self.expectation(description: "Events sent to API client expected number of times")
        expectation.expectedFulfillmentCount = 3

        apiClient.onSendAnalyticsEvent = { _ in
            expectation.fulfill()
        }

        var tasks: [Task<Void, Error>] = []
        for _ in 0 ..< 3 {
            tasks.append(Task {
                try? await self.sendEvents(numberOfEvents: 5, after: 0.5)
            })
        }
        tasks.append(Task {
            try? await self.sendEvents(numberOfEvents: 4, after: 0.5)
        })

        let expectation2 = self.expectation(description: "Wait for all tasks to complete")
        Task {
            try? await withThrowingTaskGroup(of: Void.self) { group in
                for task in tasks {
                    group.addTask {
                        try await task.value
                    }
                }
                try await group.waitForAll()
            }
            expectation2.fulfill()
        }

        await fulfillment(of: [expectation, expectation2], timeout: 60.0)

        XCTAssertEqual(apiClient.batches.count, 3, "Expected 3 batches to be sent")
        XCTAssertEqual(apiClient.batches.joined().count, 15, "Expected 15 events to be sent in total")
        XCTAssertEqual(storage.loadEvents().count, 4, "Expected 4 events to remain in storage")
    }

    func testFlush() async throws {
        let expectation = self.expectation(description: "All events flushed")

        Task {
            do {
                try await sendEvents(numberOfEvents: 4, after: 0.5)
                try await sut.flush()
            } catch {
                XCTFail("Failed to successfully flush - error message: \(error)")
            }
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 60.0)

        XCTAssertEqual(apiClient.batches.count, 1)
        XCTAssertEqual(apiClient.batches.joined().count, 4)
        XCTAssertEqual(storage.loadEvents().count, 0)
    }

    func testSendFailureDeleteSdkEvents() async throws {
        SDKSessionHelper.setUp()
        defer { SDKSessionHelper.tearDown() }

        apiClient.shouldSucceed = false

        let expectation = self.expectation(description: "Wait for all events to be sent")
        Task {
            try? await sendEvents(numberOfEvents: 4, eventType: .sdkEvent)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 60.0)

        XCTAssertEqual(storage.events.count, 4, "Expected 4 events to be stored after failure.")

        let expectation2 = self.expectation(description: "Event deletion triggered on failure")
        storage.onDeleteEventsWithUrl = { _ in
            expectation2.fulfill()
        }

        let expectation3 = self.expectation(description: "Wait for all events to be sent")
        Task {
            try? await sendEvents(numberOfEvents: 1, eventType: .sdkEvent)
            expectation3.fulfill()
        }

        await fulfillment(of: [expectation2, expectation3], timeout: 60.0)

        XCTAssertTrue(storage.events.isEmpty, "Expected all events to be deleted after failure.")
    }

    func testSendFailurePurgeAllEvents() async {
        SDKSessionHelper.setUp()
        defer { SDKSessionHelper.tearDown() }

        apiClient.shouldSucceed = false

        let expectation = self.expectation(description: "Full event purge triggered")
        storage.onDeleteAnalyticsFile = {
            expectation.fulfill()
        }

        let expectation2 = self.expectation(description: "Wait for all events to be sent")
        Task {
            do {
                try await sendEvents(numberOfEvents: 5, eventType: .sdkEvent)
                try await sendEvents(numberOfEvents: 5, eventType: .sdkEvent)
                try await sendEvents(numberOfEvents: 5, eventType: .sdkEvent)
            } catch {}
            expectation2.fulfill()
        }

        await fulfillment(of: [expectation, expectation2], timeout: 60.0)

        XCTAssertEqual(storage.loadEvents().count, 0, "Expected all events to be purged after failures.")
    }

    // MARK: Helpers

    static func createQueue() -> DispatchQueue {
        DispatchQueue(label: "AnalyticsServiceTestsQueue-\(UUID().uuidString)", qos: .background, attributes: .concurrent)
    }

    func sendEvents(
        numberOfEvents: Int,
        eventType: Analytics.Event.EventType = .message,
        after delay: TimeInterval? = nil
    ) async throws {
        let events = (0 ..< numberOfEvents).compactMap { num in
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

        for event in events {
            if let delay {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            try await sut.record(event: event)
        }
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
