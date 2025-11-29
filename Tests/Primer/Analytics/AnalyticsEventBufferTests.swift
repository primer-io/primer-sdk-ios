//
//  AnalyticsEventBufferTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class AnalyticsEventBufferTests: XCTestCase {
    private var buffer: AnalyticsEventBuffer!

    override func setUp() async throws {
        try await super.setUp()
        buffer = AnalyticsEventBuffer()
    }

    override func tearDown() async throws {
        buffer = nil
        try await super.tearDown()
    }

    // MARK: - Buffering Tests

    func testBuffer_AddsEventToBuffer() async {
        // Given
        let eventType = AnalyticsEventType.sdkInitStart
        let timestamp = Int(Date().timeIntervalSince1970)

        // When
        await buffer.buffer(eventType: eventType, metadata: nil, timestamp: timestamp)

        // Then
        let hasBuffered = await buffer.hasBufferedEvents
        let count = await buffer.count
        XCTAssertTrue(hasBuffered)
        XCTAssertEqual(count, 1)
    }

    func testBuffer_MultipleEvents_MaintainsOrder() async {
        // Given
        let event1 = AnalyticsEventType.sdkInitStart
        let event2 = AnalyticsEventType.checkoutFlowStarted
        let event3 = AnalyticsEventType.paymentMethodSelection
        let timestamp = Int(Date().timeIntervalSince1970)

        // When
        await buffer.buffer(eventType: event1, metadata: nil, timestamp: timestamp)
        await buffer.buffer(eventType: event2, metadata: nil, timestamp: timestamp + 1)
        await buffer.buffer(eventType: event3, metadata: nil, timestamp: timestamp + 2)

        // Then
        let bufferedEvents = await buffer.flush()
        XCTAssertEqual(bufferedEvents.count, 3)
        XCTAssertEqual(bufferedEvents[0].eventType, event1)
        XCTAssertEqual(bufferedEvents[1].eventType, event2)
        XCTAssertEqual(bufferedEvents[2].eventType, event3)
    }

    func testBuffer_PreservesMetadata() async {
        // Given
        let eventType = AnalyticsEventType.paymentSuccess
        let metadata: AnalyticsEventMetadata = .payment(PaymentEvent(
            paymentMethod: "PAYMENT_CARD",
            paymentId: "pay_123"
        ))
        let timestamp = Int(Date().timeIntervalSince1970)

        // When
        await buffer.buffer(eventType: eventType, metadata: metadata, timestamp: timestamp)
        let bufferedEvents = await buffer.flush()

        // Then
        XCTAssertEqual(bufferedEvents.count, 1)
        XCTAssertEqual(bufferedEvents[0].eventType, eventType)
        XCTAssertNotNil(bufferedEvents[0].metadata)
    }

    func testBuffer_PreservesTimestamp() async {
        // Given
        let eventType = AnalyticsEventType.sdkInitStart
        let originalTimestamp = Int(Date().timeIntervalSince1970) - 5 // 5 seconds ago

        // When
        await buffer.buffer(eventType: eventType, metadata: nil, timestamp: originalTimestamp)
        let bufferedEvents = await buffer.flush()

        // Then
        XCTAssertEqual(bufferedEvents.count, 1)
        XCTAssertEqual(bufferedEvents[0].timestamp, originalTimestamp, "Buffered event should preserve original timestamp")
    }

    // MARK: - Flush Tests

    func testFlush_ReturnsAllBufferedEvents() async {
        // Given
        let timestamp = Int(Date().timeIntervalSince1970)
        await buffer.buffer(eventType: .sdkInitStart, metadata: nil, timestamp: timestamp)
        await buffer.buffer(eventType: .checkoutFlowStarted, metadata: nil, timestamp: timestamp + 1)
        await buffer.buffer(eventType: .paymentMethodSelection, metadata: nil, timestamp: timestamp + 2)

        // When
        let flushedEvents = await buffer.flush()

        // Then
        XCTAssertEqual(flushedEvents.count, 3)
    }

    func testFlush_ClearsBuffer() async {
        // Given
        let timestamp = Int(Date().timeIntervalSince1970)
        await buffer.buffer(eventType: .sdkInitStart, metadata: nil, timestamp: timestamp)
        await buffer.buffer(eventType: .checkoutFlowStarted, metadata: nil, timestamp: timestamp + 1)

        // When
        _ = await buffer.flush()

        // Then
        let hasBuffered = await buffer.hasBufferedEvents
        let count = await buffer.count
        XCTAssertFalse(hasBuffered)
        XCTAssertEqual(count, 0)
    }

    func testFlush_EmptyBuffer_ReturnsEmptyArray() async {
        // Given - empty buffer

        // When
        let flushedEvents = await buffer.flush()

        // Then
        XCTAssertTrue(flushedEvents.isEmpty)
    }

    func testFlush_CanBeCalledMultipleTimes() async {
        // Given
        let timestamp = Int(Date().timeIntervalSince1970)
        await buffer.buffer(eventType: .sdkInitStart, metadata: nil, timestamp: timestamp)

        // When
        let flush1 = await buffer.flush()
        let flush2 = await buffer.flush()

        // Then
        XCTAssertEqual(flush1.count, 1)
        XCTAssertEqual(flush2.count, 0)
    }

    // MARK: - State Tests

    func testHasBufferedEvents_WhenEmpty_ReturnsFalse() async {
        // Given - empty buffer

        // When
        let hasBuffered = await buffer.hasBufferedEvents

        // Then
        XCTAssertFalse(hasBuffered)
    }

    func testHasBufferedEvents_WhenNotEmpty_ReturnsTrue() async {
        // Given
        let timestamp = Int(Date().timeIntervalSince1970)
        await buffer.buffer(eventType: .sdkInitStart, metadata: nil, timestamp: timestamp)

        // When
        let hasBuffered = await buffer.hasBufferedEvents

        // Then
        XCTAssertTrue(hasBuffered)
    }

    func testCount_ReflectsBufferedEvents() async {
        // Given
        let timestamp = Int(Date().timeIntervalSince1970)
        await buffer.buffer(eventType: .sdkInitStart, metadata: nil, timestamp: timestamp)
        await buffer.buffer(eventType: .checkoutFlowStarted, metadata: nil, timestamp: timestamp + 1)
        await buffer.buffer(eventType: .paymentMethodSelection, metadata: nil, timestamp: timestamp + 2)

        // When
        let count = await buffer.count

        // Then
        XCTAssertEqual(count, 3)
    }

    func testCount_AfterFlush_ReturnsZero() async {
        // Given
        let timestamp = Int(Date().timeIntervalSince1970)
        await buffer.buffer(eventType: .sdkInitStart, metadata: nil, timestamp: timestamp)
        await buffer.buffer(eventType: .checkoutFlowStarted, metadata: nil, timestamp: timestamp + 1)

        // When
        _ = await buffer.flush()
        let count = await buffer.count

        // Then
        XCTAssertEqual(count, 0)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentBuffering_IsThreadSafe() async {
        // When - buffer events concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0 ..< 100 {
                group.addTask {
                    let metadata: AnalyticsEventMetadata = .payment(PaymentEvent(
                        paymentMethod: "PAYMENT_CARD",
                        paymentId: "pay_\(i)"
                    ))
                    let timestamp = Int(Date().timeIntervalSince1970)
                    await self.buffer.buffer(eventType: .paymentSuccess, metadata: metadata, timestamp: timestamp)
                }
            }
        }

        // Then - all events should be buffered
        let count = await buffer.count
        XCTAssertEqual(count, 100)
    }

    func testConcurrentFlushAndBuffer_IsThreadSafe() async {
        // Given - pre-buffer some events
        let baseTimestamp = Int(Date().timeIntervalSince1970)
        for i in 0 ..< 10 {
            await buffer.buffer(
                eventType: .paymentSuccess,
                metadata: .payment(PaymentEvent(paymentMethod: "PAYMENT_CARD", paymentId: "pay_\(i)")),
                timestamp: baseTimestamp + i
            )
        }

        // When - flush and buffer concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                _ = await self.buffer.flush()
            }

            for i in 10 ..< 20 {
                group.addTask {
                    await self.buffer.buffer(
                        eventType: .paymentSuccess,
                        metadata: .payment(PaymentEvent(paymentMethod: "PAYMENT_CARD", paymentId: "pay_\(i)")),
                        timestamp: baseTimestamp + i
                    )
                }
            }
        }

        // Then - should not crash (some events may be flushed, others buffered)
        let count = await buffer.count
        XCTAssertGreaterThanOrEqual(count, 0)
        XCTAssertLessThanOrEqual(count, 20)
    }
}
