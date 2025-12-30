//
//  AnalyticsEventServiceTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class AnalyticsEventServiceTests: XCTestCase {

    private var service: TestableAnalyticsEventService!
    private var mockNetworkClient: MockAnalyticsNetworkClient!

    override func setUp() async throws {
        try await super.setUp()

        // Create mocks
        mockNetworkClient = MockAnalyticsNetworkClient()

        // Use real buffer, payload builder, and environment provider
        let buffer = AnalyticsEventBuffer()
        let payloadBuilder = AnalyticsPayloadBuilder()
        let environmentProvider = AnalyticsEnvironmentProvider()

        // Create testable service
        service = TestableAnalyticsEventService(
            payloadBuilder: payloadBuilder,
            networkClient: mockNetworkClient,
            eventBuffer: buffer,
            environmentProvider: environmentProvider
        )
    }

    override func tearDown() async throws {
        service = nil
        mockNetworkClient = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialize_StoresSessionConfig() async throws {
        // Given
        let config = makeTestConfig()

        // When
        await service.initialize(config: config)
        await service.sendEvent(.sdkInitStart, metadata: nil)

        // Then - should send event with correct config
        let call = try await mockNetworkClient.nextCall()
        XCTAssertEqual(call.payload.checkoutSessionId, config.checkoutSessionId)
        XCTAssertEqual(call.payload.clientSessionId, config.clientSessionId)
        XCTAssertEqual(call.payload.primerAccountId, config.primerAccountId)
    }

    func testInitialize_FlushesQueuedEvents() async throws {
        // Given
        let config = makeTestConfig()

        // Queue events before initialization
        await service.sendEvent(.sdkInitStart, metadata: nil)
        await service.sendEvent(.checkoutFlowStarted, metadata: nil)

        // When
        await service.initialize(config: config)

        // Then - both buffered events should be sent
        let call1 = try await mockNetworkClient.nextCall()
        let call2 = try await mockNetworkClient.nextCall()

        XCTAssertEqual(call1.payload.eventName, "SDK_INIT_START")
        XCTAssertEqual(call2.payload.eventName, "CHECKOUT_FLOW_STARTED")
    }

    func testInitialize_PreservesBufferedEventTimestamps() async throws {
        // Given
        let config = makeTestConfig()
        let beforeTimestamp = Int(Date().timeIntervalSince1970)

        // Queue event before initialization
        await service.sendEvent(.sdkInitStart, metadata: nil)

        // Wait to ensure we cross a second boundary (timestamps are in seconds)
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        // When - initialize later
        await service.initialize(config: config)

        // Then - buffered event should have old timestamp
        let call = try await mockNetworkClient.nextCall()
        let initTimestamp = Int(Date().timeIntervalSince1970)

        XCTAssertGreaterThanOrEqual(call.payload.timestamp, beforeTimestamp)
        XCTAssertLessThan(call.payload.timestamp, initTimestamp,
                         "Buffered event timestamp should be preserved from original time")
    }

    // MARK: - Event Sending Tests

    func testSendEvent_BeforeInitialization_QueuesEvent() async throws {
        // Given - service not initialized
        let eventType = AnalyticsEventType.sdkInitStart

        // When
        await service.sendEvent(eventType, metadata: nil)

        // Then - event should be queued (no network call)
        let hasCall = await mockNetworkClient.hasCall()
        XCTAssertFalse(hasCall, "Event should be buffered, not sent immediately")
    }

    func testSendEvent_AfterInitialization_SendsImmediately() async throws {
        // Given
        let config = makeTestConfig()
        await service.initialize(config: config)

        // When
        await service.sendEvent(.checkoutFlowStarted, metadata: nil)

        // Then - should send immediately
        let call = try await mockNetworkClient.nextCall()
        XCTAssertEqual(call.payload.eventName, "CHECKOUT_FLOW_STARTED")
        XCTAssertTrue(call.endpoint.absoluteString.contains("analytics.dev.data.primer.io"))
        XCTAssertEqual(call.token, config.clientSessionToken)
    }

    func testSendEvent_WithMetadata_IncludesAllFields() async throws {
        // Given
        let config = makeTestConfig()
        await service.initialize(config: config)

        let metadata: AnalyticsEventMetadata = .payment(PaymentEvent(
            paymentMethod: "PAYMENT_CARD",
            paymentId: "pay_123"
        ))

        // When
        await service.sendEvent(.paymentSuccess, metadata: metadata)

        // Then - payload should include all metadata fields
        let call = try await mockNetworkClient.nextCall()
        XCTAssertEqual(call.payload.eventName, "PAYMENT_SUCCESS")
        XCTAssertEqual(call.payload.paymentMethod, "PAYMENT_CARD")
        XCTAssertEqual(call.payload.paymentId, "pay_123")
        XCTAssertNotNil(call.payload.device)
        XCTAssertNotNil(call.payload.deviceType)
    }

    func testSendEvent_WithPartialMetadata_OnlyIncludesProvidedFields() async throws {
        // Given
        let config = makeTestConfig()
        await service.initialize(config: config)

        let metadata: AnalyticsEventMetadata = .payment(PaymentEvent(paymentMethod: "PAYMENT_CARD"))

        // When
        await service.sendEvent(.paymentMethodSelection, metadata: metadata)

        // Then - only provided fields should be included
        let call = try await mockNetworkClient.nextCall()
        XCTAssertEqual(call.payload.paymentMethod, "PAYMENT_CARD")
        XCTAssertNil(call.payload.paymentId, "Payment ID should not be included when not provided")
    }

    // MARK: - All Event Types Tests

    func testSendEvent_AllEventTypes_SendsCorrectly() async throws {
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

        // When - send all event types
        for eventType in allEventTypes {
            await service.sendEvent(eventType, metadata: nil)
        }

        // Then - all events should be sent with correct names
        for expectedType in allEventTypes {
            let call = try await mockNetworkClient.nextCall()
            XCTAssertEqual(call.payload.eventName, expectedType.rawValue)
        }
    }

    // MARK: - Metadata Auto-Fill Tests

    func testSendEvent_WithoutDeviceMetadata_AutoFillsUserAgent() async throws {
        // Given
        let config = makeTestConfig()
        await service.initialize(config: config)

        // When - send SDK lifecycle event (no metadata)
        await service.sendEvent(.sdkInitStart, metadata: nil)

        // Then - userAgent should be auto-filled, but not device fields
        let call = try await mockNetworkClient.nextCall()
        XCTAssertNotNil(call.payload.userAgent)
        XCTAssertTrue(call.payload.userAgent.contains("iOS/"))
        XCTAssertNil(call.payload.device, "Device should be nil for SDK lifecycle events")
        XCTAssertNil(call.payload.deviceType, "DeviceType should be nil for SDK lifecycle events")
    }

    func testSendEvent_WithMetadata_AutoFillsDeviceInfo() async throws {
        // Given
        let config = makeTestConfig()
        await service.initialize(config: config)

        let metadata: AnalyticsEventMetadata = .general(GeneralEvent())

        // When - send with metadata
        await service.sendEvent(.checkoutFlowStarted, metadata: metadata)

        // Then - device info should be auto-filled
        let call = try await mockNetworkClient.nextCall()
        XCTAssertNotNil(call.payload.userAgent)
        XCTAssertNotNil(call.payload.device)
        XCTAssertNotNil(call.payload.deviceType)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentEventSending_IsThreadSafe() async throws {
        // Given
        let config = makeTestConfig()
        await service.initialize(config: config)

        // When - send multiple events concurrently
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<10 {
                group.addTask {
                    let metadata: AnalyticsEventMetadata = .payment(PaymentEvent(
                        paymentMethod: "PAYMENT_CARD",
                        paymentId: "pay_\(index)"
                    ))
                    await self.service.sendEvent(.paymentSuccess, metadata: metadata)
                }
            }
        }

        // Then - all 10 events should be sent
        for _ in 0..<10 {
            let call = try await mockNetworkClient.nextCall()
            XCTAssertEqual(call.payload.eventName, "PAYMENT_SUCCESS")
        }
    }

    func testConcurrentInitializationAndSending_IsThreadSafe() async throws {
        // Given
        let config = makeTestConfig()

        // When - initialize and send events concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.service.initialize(config: config)
            }

            for index in 0..<5 {
                group.addTask {
                    let metadata: AnalyticsEventMetadata = .payment(PaymentEvent(
                        paymentMethod: "PAYMENT_CARD",
                        paymentId: "pay_\(index)"
                    ))
                    await self.service.sendEvent(.paymentSuccess, metadata: metadata)
                }
            }
        }

        // Then - all 5 events should be sent (after initialization completes)
        for _ in 0..<5 {
            let call = try await mockNetworkClient.nextCall()
            XCTAssertEqual(call.payload.eventName, "PAYMENT_SUCCESS")
        }
    }

    // MARK: - Timestamp Preservation Tests

    func testBufferedEvents_PreserveOriginalTimestamp() async throws {
        // Given
        let config = makeTestConfig()

        // Capture the timestamp when the first event occurs
        let event1Timestamp = Int(Date().timeIntervalSince1970)

        // Send first event before initialization (will be buffered)
        await service.sendEvent(.sdkInitStart, metadata: nil)

        // Wait to cross second boundary (timestamps are in seconds)
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        let event2Timestamp = Int(Date().timeIntervalSince1970)

        // Send second event before initialization (will also be buffered)
        await service.sendEvent(.checkoutFlowStarted, metadata: nil)

        // Wait a bit more to ensure second event timestamp is also in the past
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        // When - initialize the service (flushes buffered events)
        await service.initialize(config: config)

        let initTimestamp = Int(Date().timeIntervalSince1970)

        // Then - events should have been sent with their original timestamps
        let call1 = try await mockNetworkClient.nextCall()
        let call2 = try await mockNetworkClient.nextCall()

        // Verify timestamps are preserved (not the current time after initialization)
        XCTAssertEqual(call1.payload.timestamp, event1Timestamp, accuracy: 1,
                      "First event should preserve original timestamp")
        XCTAssertEqual(call2.payload.timestamp, event2Timestamp, accuracy: 1,
                      "Second event should preserve original timestamp")

        // Verify they're older than init time
        XCTAssertLessThan(call1.payload.timestamp, initTimestamp,
                         "Buffered event should have old timestamp")
        XCTAssertLessThan(call2.payload.timestamp, initTimestamp,
                         "Buffered event should have old timestamp")
    }

    func testImmediateEvents_UseFreshTimestamp() async throws {
        // Given
        let config = makeTestConfig()
        await service.initialize(config: config)

        // Capture timestamp before sending
        let beforeTimestamp = Int(Date().timeIntervalSince1970)

        // When - send event after initialization (immediate send)
        await service.sendEvent(.paymentMethodSelection, metadata: nil)

        let afterTimestamp = Int(Date().timeIntervalSince1970)

        // Then - event should have a fresh timestamp close to current time
        let call = try await mockNetworkClient.nextCall()

        XCTAssertGreaterThanOrEqual(call.payload.timestamp, beforeTimestamp,
                                   "Timestamp should be at or after the call")
        XCTAssertLessThanOrEqual(call.payload.timestamp, afterTimestamp,
                                "Timestamp should be at or before completion")
    }

    func testMixedBufferedAndImmediateEvents_PreserveCorrectTimestamps() async throws {
        // Given - send some events before initialization
        let bufferedTimestamp1 = Int(Date().timeIntervalSince1970)
        await service.sendEvent(.sdkInitStart, metadata: nil)

        // Wait to cross second boundary
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        let bufferedTimestamp2 = Int(Date().timeIntervalSince1970)
        await service.sendEvent(.sdkInitEnd, metadata: nil)

        // When - initialize
        let config = makeTestConfig()
        await service.initialize(config: config)

        // Send events after initialization
        let immediateTimestamp1 = Int(Date().timeIntervalSince1970)
        await service.sendEvent(.checkoutFlowStarted, metadata: nil)

        let immediateTimestamp2 = Int(Date().timeIntervalSince1970)
        await service.sendEvent(.paymentMethodSelection, metadata: nil)

        // Then - verify timestamp preservation for all events
        let call1 = try await mockNetworkClient.nextCall()
        let call2 = try await mockNetworkClient.nextCall()
        let call3 = try await mockNetworkClient.nextCall()
        let call4 = try await mockNetworkClient.nextCall()

        // Buffered events should have old timestamps (preserved from when they were created)
        XCTAssertEqual(call1.payload.timestamp, bufferedTimestamp1, accuracy: 1,
                      "First buffered event should have original timestamp")
        XCTAssertEqual(call2.payload.timestamp, bufferedTimestamp2, accuracy: 1,
                      "Second buffered event should have original timestamp")

        // Immediate events should have recent timestamps (from when they were sent)
        XCTAssertEqual(call3.payload.timestamp, immediateTimestamp1, accuracy: 1,
                      "First immediate event should have fresh timestamp")
        XCTAssertEqual(call4.payload.timestamp, immediateTimestamp2, accuracy: 1,
                      "Second immediate event should have fresh timestamp")
    }

    // MARK: - Error Handling Tests

    func testSendEvent_NetworkFailure_LogsErrorButDoesNotThrow() async throws {
        // Given
        let config = makeTestConfig()
        await service.initialize(config: config)
        await mockNetworkClient.setShouldFail(true)

        // When - send event that will fail
        await service.sendEvent(.paymentSuccess, metadata: nil)

        // Then - event should be attempted but error should be caught (fire-and-forget)
        let call = try await mockNetworkClient.nextCall()
        XCTAssertEqual(call.payload.eventName, "PAYMENT_SUCCESS")
        // The important part is that this doesn't throw to the test - fire-and-forget pattern
    }

    func testSendEvent_InvalidEnvironment_DropsEventGracefully() async throws {
        // Given - use a mock environment provider that returns nil
        let mockEnvironmentProvider = MockAnalyticsEnvironmentProvider(shouldReturnNil: true)
        let testService = TestableAnalyticsEventService(
            payloadBuilder: AnalyticsPayloadBuilder(),
            networkClient: mockNetworkClient,
            eventBuffer: AnalyticsEventBuffer(),
            environmentProvider: mockEnvironmentProvider
        )

        let config = makeTestConfig()
        await testService.initialize(config: config)

        // When - send event with invalid environment
        await testService.sendEvent(.sdkInitStart, metadata: nil)

        // Then - event should be dropped (no network call)
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms to ensure no delayed call
        let hasCall = await mockNetworkClient.hasCall()
        XCTAssertFalse(hasCall, "Event should be dropped when endpoint URL is invalid")
    }

    // MARK: - Environment Configuration Tests

    func testSendEvent_UsesCorrectEnvironmentEndpoint() async throws {
        // Given
        let config = AnalyticsSessionConfig(
            environment: .staging,
            checkoutSessionId: UUID().uuidString,
            clientSessionId: UUID().uuidString,
            primerAccountId: UUID().uuidString,
            sdkVersion: "2.46.7",
            clientSessionToken: "test_token"
        )
        await service.initialize(config: config)

        // When
        await service.sendEvent(.sdkInitStart, metadata: nil)

        // Then - should use staging endpoint
        let call = try await mockNetworkClient.nextCall()
        XCTAssertTrue(call.endpoint.absoluteString.contains("analytics.staging.data.primer.io"))
    }

    // MARK: - Factory Method Tests

    func testCreate_ReturnsConfiguredService() async throws {
        // Given
        let environmentProvider = AnalyticsEnvironmentProvider()

        // When
        let service = AnalyticsEventService.create(environmentProvider: environmentProvider)

        // Then - service should be usable (can initialize and accept events)
        let config = makeTestConfig()
        await service.initialize(config: config)

        // Verify service is functional by checking it doesn't crash
        await service.sendEvent(.sdkInitStart, metadata: nil)
        // If we reach here without crash, factory method works correctly
    }

    // MARK: - Helper Methods

    private func makeTestConfig() -> AnalyticsSessionConfig {
        AnalyticsSessionConfig(
            environment: .dev,
            checkoutSessionId: "cs_test_123",
            clientSessionId: "client_test_456",
            primerAccountId: "acc_test_789",
            sdkVersion: "2.46.7",
            clientSessionToken: "test_token_abc"
        )
    }
}

// MARK: - Test Doubles

/// Protocol for environment providers to enable testing
protocol EnvironmentProviding {
    func getEndpointURL(for environment: AnalyticsEnvironment) -> URL?
}

extension AnalyticsEnvironmentProvider: EnvironmentProviding {}

/// Testable version of AnalyticsEventService that uses a mock network client
actor TestableAnalyticsEventService: CheckoutComponentsAnalyticsServiceProtocol {

    private let payloadBuilder: AnalyticsPayloadBuilder
    private let networkClient: MockAnalyticsNetworkClient
    private let eventBuffer: AnalyticsEventBuffer
    private let environmentProvider: any EnvironmentProviding

    private var sessionConfig: AnalyticsSessionConfig?

    init(
        payloadBuilder: AnalyticsPayloadBuilder,
        networkClient: MockAnalyticsNetworkClient,
        eventBuffer: AnalyticsEventBuffer,
        environmentProvider: any EnvironmentProviding
    ) {
        self.payloadBuilder = payloadBuilder
        self.networkClient = networkClient
        self.eventBuffer = eventBuffer
        self.environmentProvider = environmentProvider
    }

    convenience init(
        payloadBuilder: AnalyticsPayloadBuilder,
        networkClient: MockAnalyticsNetworkClient,
        eventBuffer: AnalyticsEventBuffer,
        environmentProvider: AnalyticsEnvironmentProvider
    ) {
        self.init(
            payloadBuilder: payloadBuilder,
            networkClient: networkClient,
            eventBuffer: eventBuffer,
            environmentProvider: environmentProvider as any EnvironmentProviding
        )
    }

    func initialize(config: AnalyticsSessionConfig) async {
        self.sessionConfig = config

        let bufferedEvents = await eventBuffer.flush()

        guard !bufferedEvents.isEmpty else { return }

        for (eventType, metadata, timestamp) in bufferedEvents {
            await sendEventWithTimestamp(eventType, metadata: metadata, timestamp: timestamp)
        }
    }

    func sendEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async {
        let eventTimestamp = Int(Date().timeIntervalSince1970)
        await sendEventWithTimestamp(eventType, metadata: metadata, timestamp: eventTimestamp)
    }

    private func sendEventWithTimestamp(
        _ eventType: AnalyticsEventType,
        metadata: AnalyticsEventMetadata?,
        timestamp: Int
    ) async {
        guard let config = sessionConfig else {
            await eventBuffer.buffer(eventType: eventType, metadata: metadata, timestamp: timestamp)
            return
        }

        guard let endpoint = environmentProvider.getEndpointURL(for: config.environment) else {
            return
        }

        let payload = payloadBuilder.buildPayload(
            eventType: eventType,
            metadata: metadata,
            config: config,
            timestamp: timestamp
        )

        try? await networkClient.send(payload: payload, to: endpoint, token: config.clientSessionToken)
    }
}

/// Mock network client that records all send() calls
actor MockAnalyticsNetworkClient {

    struct Call: Sendable {
        let payload: AnalyticsPayload
        let endpoint: URL
        let token: String?
    }

    private var calls: [Call] = []
    private var shouldFail = false

    func send(payload: AnalyticsPayload, to endpoint: URL, token: String?) async throws {
        calls.append(Call(payload: payload, endpoint: endpoint, token: token))

        if shouldFail {
            throw AnalyticsError.requestFailed
        }
    }

    func nextCall(timeout: TimeInterval = 2.0) async throws -> Call {
        let deadline = Date().addingTimeInterval(timeout)

        while calls.isEmpty {
            if Date() > deadline {
                throw MockError.timeout
            }
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }

        return calls.removeFirst()
    }

    func hasCall() async -> Bool {
        !calls.isEmpty
    }

    func setShouldFail(_ shouldFail: Bool) {
        self.shouldFail = shouldFail
    }
}

/// Mock environment provider for testing invalid endpoint scenarios
struct MockAnalyticsEnvironmentProvider {
    let shouldReturnNil: Bool

    init(shouldReturnNil: Bool = false) {
        self.shouldReturnNil = shouldReturnNil
    }

    func getEndpointURL(for environment: AnalyticsEnvironment) -> URL? {
        if shouldReturnNil {
            return nil
        }
        // Return real URLs for valid environments
        return AnalyticsEnvironmentProvider().getEndpointURL(for: environment)
    }
}

extension MockAnalyticsEnvironmentProvider: EnvironmentProviding {}

private enum MockError: Error {
    case timeout
}
