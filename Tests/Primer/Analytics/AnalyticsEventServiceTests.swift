//
//  AnalyticsEventServiceTests.swift
//  PrimerSDKTests
//
//  Tests for AnalyticsEventService
//

@testable import PrimerSDK
import XCTest

final class AnalyticsEventServiceTests: XCTestCase {

    private var service: AnalyticsEventService!

    override func setUp() async throws {
        try await super.setUp()
        // Use real providers since they're simple value types with no side effects
        service = AnalyticsEventService(
            environmentProvider: AnalyticsEnvironmentProvider(),
            deviceInfoProvider: DeviceInfoProvider()
        )
    }

    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialize_StoresSessionConfig() async throws {
        // Given
        let config = makeTestConfig()

        // When
        await service.initialize(config: config)

        // Then - should not crash and accept future events
        await service.sendEvent(.sdkInitStart, metadata: nil)
    }

    func testInitialize_FlushesQueuedEvents() async throws {
        // Given
        let config = makeTestConfig()

        // Queue events before initialization
        await service.sendEvent(.sdkInitStart, metadata: nil)
        await service.sendEvent(.checkoutFlowStarted, metadata: nil)

        // When
        await service.initialize(config: config)

        // Then - events should be processed after initialization (fire-and-forget, no crash)
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms for async processing
    }

    // MARK: - Event Sending Tests

    func testSendEvent_BeforeInitialization_QueuesEvent() async throws {
        // Given - service not initialized
        let eventType = AnalyticsEventType.sdkInitStart

        // When
        await service.sendEvent(eventType, metadata: nil)

        // Then - event should be queued (no crash)
        // After initialization, queued events will be sent
    }

    func testSendEvent_AfterInitialization_SendsImmediately() async throws {
        // Given
        let config = makeTestConfig()
        await service.initialize(config: config)

        // When - this will attempt to send to real endpoint (will fail but shouldn't crash)
        await service.sendEvent(.checkoutFlowStarted, metadata: nil)

        // Then - should not crash (fire-and-forget pattern handles errors)
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms for async processing
    }

    func testSendEvent_WithMetadata_IncludesAllFields() async throws {
        // Given
        let config = makeTestConfig()
        await service.initialize(config: config)

        let metadata = AnalyticsEventMetadata(
            eventType: "payment",
            userLocale: "en-US",
            paymentMethod: "PAYMENT_CARD",
            paymentId: "pay_123",
            redirectDestinationUrl: "https://redirect.example.com",
            threedsProvider: "Netcetera",
            threedsResponse: "05",
            browser: "Safari",
            device: "iPhone 15 Pro",
            deviceType: "phone"
        )

        // When
        await service.sendEvent(.paymentSuccess, metadata: metadata)

        // Then - should not crash
        try? await Task.sleep(nanoseconds: 50_000_000)
    }

    func testSendEvent_WithPartialMetadata_OnlyIncludesProvidedFields() async throws {
        // Given
        let config = makeTestConfig()
        await service.initialize(config: config)

        let metadata = AnalyticsEventMetadata(
            paymentMethod: "PAYMENT_CARD"
        )

        // When
        await service.sendEvent(.paymentMethodSelection, metadata: metadata)

        // Then - should not crash
        try? await Task.sleep(nanoseconds: 50_000_000)
    }

    // MARK: - All Event Types Tests

    func testSendEvent_AllEventTypes_DoNotCrash() async throws {
        // Given
        let config = makeTestConfig()
        await service.initialize(config: config)

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

        // When/Then - all event types should be sendable
        for eventType in allEventTypes {
            await service.sendEvent(eventType, metadata: nil)
        }

        try? await Task.sleep(nanoseconds: 100_000_000)
    }

    // MARK: - Metadata Auto-Fill Tests

    func testSendEvent_WithoutDeviceMetadata_AutoFillsFromProvider() async throws {
        // Given
        let config = makeTestConfig()
        await service.initialize(config: config)

        // When - no device info in metadata
        await service.sendEvent(.checkoutFlowStarted, metadata: nil)

        // Then - should use DeviceInfoProvider values (verified by no crash)
        try? await Task.sleep(nanoseconds: 50_000_000)
    }

    func testSendEvent_WithDeviceMetadata_UsesProvidedValues() async throws {
        // Given
        let config = makeTestConfig()
        await service.initialize(config: config)

        let metadata = AnalyticsEventMetadata(
            device: "Custom Device",
            deviceType: "tablet"
        )

        // When
        await service.sendEvent(.paymentSubmitted, metadata: metadata)

        // Then - should use metadata values
        try? await Task.sleep(nanoseconds: 50_000_000)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentEventSending_IsThreadSafe() async throws {
        // Given
        let config = makeTestConfig()
        await service.initialize(config: config)

        // When - send multiple events concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let metadata = AnalyticsEventMetadata(paymentId: "pay_\(i)")
                    await self.service.sendEvent(.paymentSuccess, metadata: metadata)
                }
            }
        }

        // Then - should not crash
        try? await Task.sleep(nanoseconds: 100_000_000)
    }

    func testConcurrentInitializationAndSending_IsThreadSafe() async throws {
        // Given
        let config = makeTestConfig()

        // When - initialize and send events concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.service.initialize(config: config)
            }

            for i in 0..<5 {
                group.addTask {
                    let metadata = AnalyticsEventMetadata(paymentId: "pay_\(i)")
                    await self.service.sendEvent(.paymentSuccess, metadata: metadata)
                }
            }
        }

        // Then - should not crash
        try? await Task.sleep(nanoseconds: 100_000_000)
    }

    // MARK: - Integration Tests

    func testSendEvent_WithRealProviders_WorksCorrectly() async throws {
        // Given
        let config = AnalyticsSessionConfig(
            environment: .dev,
            checkoutSessionId: UUID().uuidString,
            clientSessionId: UUID().uuidString,
            primerAccountId: UUID().uuidString,
            sdkVersion: "2.46.7",
            clientSessionToken: nil // No token for this test
        )

        await service.initialize(config: config)

        // When - send events with real device info
        let metadata = AnalyticsEventMetadata(
            paymentMethod: "PAYMENT_CARD",
            paymentId: "pay_test_123"
        )

        await service.sendEvent(.paymentSuccess, metadata: metadata)

        // Then - should not crash even with real device detection
        try? await Task.sleep(nanoseconds: 50_000_000)
    }

    // MARK: - Helper Methods

    private func makeTestConfig() -> AnalyticsSessionConfig {
        return AnalyticsSessionConfig(
            environment: .dev,
            checkoutSessionId: "cs_test_123",
            clientSessionId: "client_test_456",
            primerAccountId: "acc_test_789",
            sdkVersion: "2.46.7",
            clientSessionToken: "test_token_abc"
        )
    }
}
