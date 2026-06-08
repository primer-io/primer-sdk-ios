//
//  CheckoutComponentsAnalyticsInteractorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class CheckoutComponentsAnalyticsInteractorTests: XCTestCase {

    // MARK: - Task Priority Tests

    func testTrackEventPropagatesTaskPriority() async throws {
        let service = SpyAnalyticsService()
        let interactor = DefaultAnalyticsInteractor(eventService: service)
        let priority: TaskPriority = .high

        let task = Task(priority: priority) {
            await interactor.trackEvent(.sdkInitStart, metadata: nil)
        }

        await task.value
        let call = try await service.nextCall()
        XCTAssertEqual(call.priority, priority)
    }

    // MARK: - Basic Event Tracking Tests

    func testTrackEvent_WithoutMetadata_CallsService() async throws {
        // Given
        let service = SpyAnalyticsService()
        let interactor = DefaultAnalyticsInteractor(eventService: service)

        // When
        await interactor.trackEvent(.sdkInitStart, metadata: nil)

        // Then
        let call = try await service.nextCall()
        XCTAssertEqual(call.eventType, .sdkInitStart)
        XCTAssertNil(call.metadata)
    }

    func testTrackEvent_WithMetadata_PassesMetadataToService() async throws {
        // Given
        let service = SpyAnalyticsService()
        let interactor = DefaultAnalyticsInteractor(eventService: service)
        let metadata: AnalyticsEventMetadata = .payment(PaymentEvent(
            paymentMethod: "PAYMENT_CARD",
            paymentId: "pay_123"
        ))

        // When
        await interactor.trackEvent(.paymentSuccess, metadata: metadata)

        // Then
        let call = try await service.nextCall()
        XCTAssertEqual(call.eventType, .paymentSuccess)
        XCTAssertNotNil(call.metadata)
        XCTAssertEqual(call.metadata?.paymentMethod, "PAYMENT_CARD")
        XCTAssertEqual(call.metadata?.paymentId, "pay_123")
    }

    // MARK: - All Event Types Tests

    func testTrackEvent_AllEventTypes_CallsService() async throws {
        // Given
        let service = SpyAnalyticsService()
        let interactor = DefaultAnalyticsInteractor(eventService: service)

        let allEventTypes: [AnalyticsEventType] = [
            .sdkInitStart,
            .sdkInitEnd,
            .checkoutFlowStarted,
            .paymentMethodSelection,
            .paymentDetailsEntered,
            .paymentSubmitted,
            .paymentProcessingStarted,
            .paymentRedirectToThirdParty,
            .paymentThreeds,
            .paymentSuccess,
            .paymentFailure,
            .paymentReattempted,
            .paymentFlowExited
        ]

        // When/Then - all event types should be trackable
        for eventType in allEventTypes {
            await interactor.trackEvent(eventType, metadata: nil)
            let call = try await service.nextCall()
            XCTAssertEqual(call.eventType, eventType)
        }
    }

    // MARK: - Concurrent Tracking Tests

    func testTrackEvent_ConcurrentCalls_AllCompleteSuccessfully() async throws {
        // Given
        let service = SpyAnalyticsService()
        let interactor = DefaultAnalyticsInteractor(eventService: service)

        // When - track multiple events concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let metadata: AnalyticsEventMetadata = .payment(PaymentEvent(
                        paymentMethod: "PAYMENT_CARD",
                        paymentId: "pay_\(i)"
                    ))
                    await interactor.trackEvent(.paymentSuccess, metadata: metadata)
                }
            }
        }

        // Then - all events should be tracked
        for _ in 0..<10 {
            let call = try await service.nextCall()
            XCTAssertEqual(call.eventType, .paymentSuccess)
        }
    }

    // MARK: - Delivery Ordering Tests

    func testTrackEvent_AwaitsServiceDelivery() async throws {
        // Given
        let service = SpyAnalyticsService(delayNanoseconds: 100_000_000) // 100ms delay
        let interactor = DefaultAnalyticsInteractor(eventService: service)

        // When
        await interactor.trackEvent(.sdkInitStart, metadata: nil)

        // Then - awaiting trackEvent guarantees the event was handed off to the service
        let call = try await service.nextCall()
        XCTAssertEqual(call.eventType, .sdkInitStart)
    }

    // MARK: - Metadata Tests

    func testTrackEvent_With3DSMetadata_PassesToService() async throws {
        // Given
        let service = SpyAnalyticsService()
        let interactor = DefaultAnalyticsInteractor(eventService: service)
        let metadata: AnalyticsEventMetadata = .threeDS(ThreeDSEvent(
            paymentMethod: "PAYMENT_CARD",
            provider: "Netcetera",
            response: "05"
        ))

        // When
        await interactor.trackEvent(.paymentThreeds, metadata: metadata)

        // Then
        let call = try await service.nextCall()
        XCTAssertEqual(call.metadata?.threedsProvider, "Netcetera")
        XCTAssertEqual(call.metadata?.threedsResponse, "05")
    }

    func testTrackEvent_WithRedirectMetadata_PassesToService() async throws {
        // Given
        let service = SpyAnalyticsService()
        let interactor = DefaultAnalyticsInteractor(eventService: service)
        let metadata: AnalyticsEventMetadata = .redirect(RedirectEvent(
            paymentMethod: "PAYPAL",
            destinationUrl: "https://example.com/redirect"
        ))

        // When
        await interactor.trackEvent(.paymentRedirectToThirdParty, metadata: metadata)

        // Then
        let call = try await service.nextCall()
        XCTAssertEqual(call.metadata?.redirectDestinationUrl, "https://example.com/redirect")
    }
}

// MARK: - Test Doubles

private actor SpyAnalyticsService: CheckoutComponentsAnalyticsServiceProtocol {

    struct Call: Sendable {
        let priority: TaskPriority
        let isCancelled: Bool
        let eventType: AnalyticsEventType
        let metadata: AnalyticsEventMetadata?
    }

    private var buffer: [Call] = []
    private var waiters: [CheckedContinuation<Call, Never>] = []
    private let delayNanoseconds: UInt64

    init(delayNanoseconds: UInt64 = 0) {
        self.delayNanoseconds = delayNanoseconds
    }

    func initialize(config: AnalyticsSessionConfig) async {}

    func sendEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async {
        let call = Call(
            priority: Task.currentPriority,
            isCancelled: Task.isCancelled,
            eventType: eventType,
            metadata: metadata
        )
        if waiters.isEmpty {
            buffer.append(call)
        } else {
            waiters.removeFirst().resume(returning: call)
        }
        if delayNanoseconds > 0 {
            // why: scenario input — a deliberately-slow service the delivery-ordering test depends on; no signal to await.
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }
    }

    /// Awaits the next recorded call, waking immediately when an event arrives
    /// (no polling). Times out via a race against the deadline.
    func nextCall(timeout: TimeInterval = 1) async throws -> Call {
        if !buffer.isEmpty {
            return buffer.removeFirst()
        }
        return try await withThrowingTaskGroup(of: Call.self) { group in
            group.addTask { await self.awaitNextCall() }
            group.addTask {
                // why: deadline-race primitive for the event-driven mock (mirrors XCTestCase+Async helpers); not a poll-and-assert wait.
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw WaitError.timeout
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    private func awaitNextCall() async -> Call {
        await withCheckedContinuation { waiters.append($0) }
    }
}

private enum WaitError: Error {
    case timeout
}
