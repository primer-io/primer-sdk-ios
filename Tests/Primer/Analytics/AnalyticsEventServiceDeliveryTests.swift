//
//  AnalyticsEventServiceDeliveryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

/// Delivery behaviour of the real `AnalyticsEventService` actor: ordering, retries, the queue cap,
/// pre-init buffering, and the contract envelope fields. Uses a real `AnalyticsEventSending` double
/// instead of a reimplementation, so retry/funnel/queue logic under test is the production code.
final class AnalyticsEventServiceDeliveryTests: XCTestCase {

    private var client: RecordingAnalyticsNetworkClient!

    override func setUp() {
        super.setUp()
        client = RecordingAnalyticsNetworkClient()
    }

    override func tearDown() {
        client = nil
        super.tearDown()
    }

    // MARK: - Ordering

    func test_sendEvent_multipleEvents_deliveredInOrder() async throws {
        // Given
        let service = makeService()
        await service.initialize(config: makeConfig())

        // When
        await service.sendEvent(.sdkInitStart, metadata: nil)
        await service.sendEvent(.sdkInitEnd, metadata: nil)
        await service.sendEvent(.checkoutFlowStarted, metadata: nil)

        // Then
        let calls = try await client.waitForCalls(count: 3)
        XCTAssertEqual(calls.map(\.payload.eventName), ["SDK_INIT_START", "SDK_INIT_END", "CHECKOUT_FLOW_STARTED"])
    }

    // MARK: - Retry: retryable errors

    func test_sendEvent_httpStatus5xx_retriesUpToThreeSendsTotal() async throws {
        try await assertRetriesUpToCap(error: AnalyticsError.httpStatus(503))
    }

    func test_sendEvent_httpStatus408_retriesUpToThreeSendsTotal() async throws {
        try await assertRetriesUpToCap(error: AnalyticsError.httpStatus(408))
    }

    func test_sendEvent_httpStatus429_retriesUpToThreeSendsTotal() async throws {
        try await assertRetriesUpToCap(error: AnalyticsError.httpStatus(429))
    }

    func test_sendEvent_urlError_retriesUpToThreeSendsTotal() async throws {
        try await assertRetriesUpToCap(error: URLError(.notConnectedToInternet))
    }

    func test_sendEvent_retryableErrorThenSuccess_stopsRetryingOnceItSucceeds() async throws {
        // Given
        await client.enqueueErrors([AnalyticsError.httpStatus(500)])
        let service = makeService()
        await service.initialize(config: makeConfig())

        // When
        await service.sendEvent(.sdkInitStart, metadata: nil)

        // Then — 1 failure + 1 success, no 3rd attempt
        let calls = try await client.waitForCalls(count: 2)
        XCTAssertEqual(calls.count, 2)
        try await assertNoFurtherCalls()
    }

    // MARK: - Retry: non-retryable errors

    func test_sendEvent_nonRetryable4xx_doesNotRetry() async throws {
        // Given
        await client.enqueueErrors([AnalyticsError.httpStatus(400)])
        let service = makeService()
        await service.initialize(config: makeConfig())

        // When
        await service.sendEvent(.sdkInitStart, metadata: nil)

        // Then
        let calls = try await client.waitForCalls(count: 1)
        XCTAssertEqual(calls.count, 1)
        try await assertNoFurtherCalls()
    }

    // MARK: - Queue cap

    func test_sendEvent_queueExceedsFifty_dropsOldestBeyondCap() async throws {
        // Given — the first event is dequeued and blocks in flight, so the remaining sends land
        // in the queue and can be capped deterministically.
        await client.blockNextSend()
        let service = makeService()
        await service.initialize(config: makeConfig())

        await service.sendEvent(.sdkInitEnd, metadata: .payment(PaymentEvent(paymentMethod: "METHOD_1")))
        try await client.waitUntilBlocking()

        for index in 2...55 {
            await service.sendEvent(.sdkInitEnd, metadata: .payment(PaymentEvent(paymentMethod: "METHOD_\(index)")))
        }

        // When
        await client.release()

        // Then — item 1 (already in flight) plus the newest 50 of the remaining 54 survive;
        // methods 2-5 were evicted from the front of the queue while it was over the 50 cap.
        let calls = try await client.waitForCalls(count: 51)
        let methods = calls.compactMap(\.payload.paymentMethod)
        XCTAssertEqual(methods.count, 51)
        XCTAssertEqual(methods.first, "METHOD_1")
        XCTAssertFalse(methods.contains("METHOD_2"))
        XCTAssertFalse(methods.contains("METHOD_5"))
        XCTAssertTrue(methods.contains("METHOD_6"))
        XCTAssertTrue(methods.contains("METHOD_55"))
    }

    // MARK: - Buffering before initialize

    func test_sendEvent_beforeInitialize_buffersUntilInitializeThenSends() async throws {
        // Given
        let service = makeService()

        // When
        await service.sendEvent(.sdkInitStart, metadata: nil)

        // Then — nothing sent yet
        // why: negative assertion — sendEvent already awaited fully, there is no positive
        // signal to await before initialize is called.
        try await Task.sleep(nanoseconds: 50_000_000)
        let countBeforeInit = await client.calls.count
        XCTAssertEqual(countBeforeInit, 0)

        // When
        await service.initialize(config: makeConfig())

        // Then
        let calls = try await client.waitForCalls(count: 1)
        XCTAssertEqual(calls.first?.payload.eventName, "SDK_INIT_START")
    }

    // MARK: - Contract envelope fields

    func test_sendEvent_payloadCarriesContractVersionAndIntegrationSurface() async throws {
        // Given
        let service = makeService(integrationSurfaceProvider: { "swift_ui" })
        await service.initialize(config: makeConfig())

        // When
        await service.sendEvent(.sdkInitStart, metadata: nil)

        // Then
        let calls = try await client.waitForCalls(count: 1)
        XCTAssertEqual(calls.first?.payload.contractVersion, 2)
        XCTAssertEqual(calls.first?.payload.integrationSurface, "swift_ui")
    }

    // MARK: - Helpers

    private func makeService(
        integrationSurfaceProvider: @escaping @Sendable () async -> String? = { nil }
    ) -> AnalyticsEventService {
        AnalyticsEventService(
            payloadBuilder: AnalyticsPayloadBuilder(),
            networkClient: client,
            eventBuffer: AnalyticsEventBuffer(),
            environmentProvider: AnalyticsEnvironmentProvider(),
            integrationSurfaceProvider: integrationSurfaceProvider,
            retryDelays: [0, 0]
        )
    }

    private func makeConfig() -> AnalyticsSessionConfig {
        AnalyticsSessionConfig(
            environment: .dev,
            checkoutSessionId: "cs_delivery_test",
            clientSessionId: "client_delivery_test",
            primerAccountId: "acc_delivery_test",
            sdkVersion: "3.0.0",
            clientSessionToken: "token_delivery_test"
        )
    }

    private func assertRetriesUpToCap(error: Error, file: StaticString = #filePath, line: UInt = #line) async throws {
        await client.enqueueErrors(Array(repeating: error, count: 3))
        let service = makeService()
        await service.initialize(config: makeConfig())

        await service.sendEvent(.sdkInitStart, metadata: nil)

        let calls = try await client.waitForCalls(count: 3)
        XCTAssertEqual(calls.count, 3, file: file, line: line)
        try await assertNoFurtherCalls(file: file, line: line)
    }

    private func assertNoFurtherCalls(file: StaticString = #filePath, line: UInt = #line) async throws {
        let countBefore = await client.calls.count
        // why: negative assertion — the prior wait already confirmed the expected calls landed;
        // this only needs a short tick to confirm no straggler arrives.
        try await Task.sleep(nanoseconds: 50_000_000)
        let countAfter = await client.calls.count
        XCTAssertEqual(countAfter, countBefore, file: file, line: line)
    }
}

// MARK: - Test Double

/// Records every `send` call and can inject errors or block delivery, so tests can drive the real
/// `AnalyticsEventService`'s retry, ordering and queue-cap logic deterministically.
private actor RecordingAnalyticsNetworkClient: AnalyticsEventSending {

    struct Call: Sendable {
        let payload: AnalyticsPayload
        let endpoint: URL
        let token: String?
    }

    private(set) var calls: [Call] = []
    private(set) var isBlocking = false
    private var errorQueue: [Error] = []
    private var shouldBlockNext = false
    private var continuation: CheckedContinuation<Void, Never>?

    func send(payload: AnalyticsPayload, to endpoint: URL, token: String?) async throws {
        if shouldBlockNext {
            shouldBlockNext = false
            isBlocking = true
            await withCheckedContinuation { self.continuation = $0 }
            isBlocking = false
        }
        calls.append(Call(payload: payload, endpoint: endpoint, token: token))
        if !errorQueue.isEmpty {
            throw errorQueue.removeFirst()
        }
    }

    func enqueueErrors(_ errors: [Error]) {
        errorQueue.append(contentsOf: errors)
    }

    func blockNextSend() {
        shouldBlockNext = true
    }

    func release() {
        continuation?.resume()
        continuation = nil
    }

    func waitUntilBlocking(timeout: TimeInterval = 2.0) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !isBlocking {
            if Date() > deadline { throw TestError.timeout }
            try await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    func waitForCalls(count: Int, timeout: TimeInterval = 2.0) async throws -> [Call] {
        let deadline = Date().addingTimeInterval(timeout)
        while calls.count < count {
            if Date() > deadline { throw TestError.timeout }
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        return calls
    }
}
