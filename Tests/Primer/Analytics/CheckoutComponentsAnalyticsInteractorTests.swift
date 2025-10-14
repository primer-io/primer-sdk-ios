//
//  CheckoutComponentsAnalyticsInteractorTests.swift
//  PrimerSDKTests
//

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
        let metadata = AnalyticsEventMetadata(
            paymentMethod: "PAYMENT_CARD",
            paymentId: "pay_123"
        )

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
                    let metadata = AnalyticsEventMetadata(paymentId: "pay_\(i)")
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

    // MARK: - Fire-and-Forget Pattern Tests

    func testTrackEvent_DoesNotBlock() async throws {
        // Given
        let service = SpyAnalyticsService(delayNanoseconds: 100_000_000) // 100ms delay
        let interactor = DefaultAnalyticsInteractor(eventService: service)

        // When
        let startTime = Date()
        await interactor.trackEvent(.sdkInitStart, metadata: nil)
        let elapsed = Date().timeIntervalSince(startTime)

        // Then - should return almost immediately (fire-and-forget)
        XCTAssertLessThan(elapsed, 0.05, "trackEvent should not block caller")
    }

    // MARK: - Metadata Tests

    func testTrackEvent_With3DSMetadata_PassesToService() async throws {
        // Given
        let service = SpyAnalyticsService()
        let interactor = DefaultAnalyticsInteractor(eventService: service)
        let metadata = AnalyticsEventMetadata(
            threedsProvider: "Netcetera",
            threedsResponse: "05"
        )

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
        let metadata = AnalyticsEventMetadata(
            redirectDestinationUrl: "https://example.com/redirect"
        )

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

    private var calls: [Call] = []
    private let delayNanoseconds: UInt64

    init(delayNanoseconds: UInt64 = 0) {
        self.delayNanoseconds = delayNanoseconds
    }

    func initialize(config: AnalyticsSessionConfig) async {}

    func sendEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async {
        calls.append(Call(
            priority: Task.currentPriority,
            isCancelled: Task.isCancelled,
            eventType: eventType,
            metadata: metadata
        ))
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }
    }

    func nextCall(timeout: TimeInterval = 1) async throws -> Call {
        let deadline = Date().addingTimeInterval(timeout)
        while calls.isEmpty {
            if Date() > deadline {
                throw WaitError.timeout
            }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        return calls.removeFirst()
    }
}

private enum WaitError: Error {
    case timeout
}
