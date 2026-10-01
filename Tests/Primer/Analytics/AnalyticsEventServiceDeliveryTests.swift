//
//  AnalyticsEventServiceDeliveryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import UIKit
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

    func test_recordThreeDSOutcome_isSentWithTheAttemptsSuccess() async throws {
        // Given
        let service = makeService()
        await service.initialize(config: makeConfig())
        await service.sendEvent(.paymentMethodSelection, metadata: .payment(PaymentEvent(paymentMethod: "PAYMENT_CARD")))

        // When
        await service.recordThreeDSOutcome(AnalyticsFunnelState.ThreeDSOutcome(authenticationOutcome: "AUTH_SUCCESS", skippedReasonCode: nil))
        await service.sendEvent(.paymentSuccess, metadata: .payment(PaymentEvent(paymentMethod: "PAYMENT_CARD", paymentId: "pay_1")))

        // Then
        let calls = try await client.waitForCalls(count: 2)
        XCTAssertNil(calls.first?.payload.authenticationOutcome)
        XCTAssertEqual(calls.last?.payload.authenticationOutcome, "AUTH_SUCCESS")
    }

    // MARK: - A new session

    func test_sendEvent_whileTheSessionStarts_waitsForItAndKeepsTheOrder() async throws {
        // Given
        let surface = SurfaceGate()
        let service = makeService(integrationSurfaceProvider: { await surface.wait() })
        await service.sendEvent(.sdkInitStart, metadata: nil)
        let starting = Task { await service.initialize(config: makeConfig()) }
        try await surface.waitUntilAsked()

        // When
        await service.sendEvent(.sdkInitEnd, metadata: nil)
        await surface.answer("swift_ui")
        await starting.value

        // Then
        let calls = try await client.waitForCalls(count: 2)
        XCTAssertEqual(calls.map(\.payload.eventName), ["SDK_INIT_START", "SDK_INIT_END"])
        XCTAssertEqual(calls.last?.payload.integrationSurface, "swift_ui")
    }

    // MARK: - Retry delays and the background flush

    func test_retry_waitsTheBackoffDelaysBetweenSends() async throws {
        // Given
        let sleeps = SleepRecorder()
        await client.enqueueErrors([URLError(.timedOut), URLError(.timedOut)])
        let service = makeService(retryDelays: [1_000, 2_000], sleep: { await sleeps.record($0) })
        await service.initialize(config: makeConfig())

        // When
        await service.sendEvent(.sdkInitStart, metadata: nil)

        // Then
        _ = try await client.waitForCalls(count: 3)
        let delays = await sleeps.delays
        XCTAssertEqual(delays, [1_000, 2_000])
    }

    func test_background_keepsTheAppAwakeUntilTheQueueDrains_andSkipsTheBackoff() async throws {
        // Given
        let sleeps = SleepRecorder()
        let tasks = await MainActor.run { BackgroundTaskRecorder() }
        let service = makeService(
            retryDelays: [1_000, 2_000],
            sleep: { await sleeps.record($0) },
            beginBackgroundTask: { tasks.begin() },
            endBackgroundTask: { tasks.end($0) }
        )
        await service.initialize(config: makeConfig())
        await client.blockNextSend()
        await client.enqueueErrors([URLError(.timedOut)])
        await service.sendEvent(.sdkInitStart, metadata: nil)
        try await client.waitUntilBlocking()

        // When
        try await postBackgroundUntil { await MainActor.run { !tasks.begun.isEmpty } }
        await client.release()

        // Then
        _ = try await client.waitForCalls(count: 2)
        try await waitUntil { await MainActor.run { tasks.ended.count == tasks.begun.count } }
        let delays = await sleeps.delays
        XCTAssertEqual(delays, [], "A retry during the background flush must not wait")
    }

    // MARK: - Helpers

    private func makeService(
        integrationSurfaceProvider: @escaping @Sendable () async -> String? = { nil },
        retryDelays: [UInt64] = [0, 0],
        sleep: @escaping @Sendable (UInt64) async -> Void = { _ in },
        beginBackgroundTask: @escaping @MainActor @Sendable () -> UIBackgroundTaskIdentifier = { .invalid },
        endBackgroundTask: @escaping @MainActor @Sendable (UIBackgroundTaskIdentifier) -> Void = { _ in }
    ) -> AnalyticsEventService {
        AnalyticsEventService(
            payloadBuilder: AnalyticsPayloadBuilder(),
            networkClient: client,
            eventBuffer: AnalyticsEventBuffer(),
            environmentProvider: AnalyticsEnvironmentProvider(),
            integrationSurfaceProvider: integrationSurfaceProvider,
            retryDelays: retryDelays,
            sleep: sleep,
            beginBackgroundTask: beginBackgroundTask,
            endBackgroundTask: endBackgroundTask
        )
    }

    /// The observer attaches on a background task, so the post repeats until it is seen.
    private func postBackgroundUntil(_ condition: () async -> Bool) async throws {
        let deadline = Date().addingTimeInterval(2)
        while await !condition() {
            NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
            if Date() > deadline { throw TestError.timeout }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    private func waitUntil(_ condition: () async -> Bool) async throws {
        let deadline = Date().addingTimeInterval(2)
        while await !condition() {
            if Date() > deadline { throw TestError.timeout }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
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

/// Holds the integration surface lookup open, so a test can send events while the session starts.
private actor SurfaceGate {
    private var continuation: CheckedContinuation<String?, Never>?

    func wait() async -> String? {
        await withCheckedContinuation { continuation = $0 }
    }

    func answer(_ surface: String?) {
        continuation?.resume(returning: surface)
        continuation = nil
    }

    func waitUntilAsked(timeout: TimeInterval = 2.0) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while continuation == nil {
            if Date() > deadline { throw TestError.timeout }
            try await Task.sleep(nanoseconds: 5_000_000)
        }
    }
}

private actor SleepRecorder {
    private(set) var delays: [UInt64] = []

    func record(_ delay: UInt64) {
        delays.append(delay)
    }
}

@MainActor
private final class BackgroundTaskRecorder {
    private(set) var begun: [UIBackgroundTaskIdentifier] = []
    private(set) var ended: [UIBackgroundTaskIdentifier] = []

    func begin() -> UIBackgroundTaskIdentifier {
        let id = UIBackgroundTaskIdentifier(rawValue: begun.count + 1)
        begun.append(id)
        return id
    }

    func end(_ id: UIBackgroundTaskIdentifier) {
        ended.append(id)
    }
}
