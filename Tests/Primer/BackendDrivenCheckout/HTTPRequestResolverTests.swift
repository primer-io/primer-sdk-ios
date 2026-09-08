//
//  HTTPRequestResolverTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerNetworking
@testable import PrimerSDK
@_spi(PrimerInternal) import PrimerStepResolver
import XCTest

final class HTTPRequestResolverTests: XCTestCase {

    // MARK: - Attempts

    func testSingleAttemptWhenNoRetryPolicy() async throws {
        let dispatcher = ScriptedRequestDispatcher(statuses: [503, 200])
        let sut = HTTPRequestResolver(dispatcher: dispatcher)

        let result = try await sut.resolve(step())

        XCTAssertEqual(dispatcher.dispatchCount, 1)
        XCTAssertEqual(result.outcome, .error)
    }

    func testRetriesListedStatusUntilSuccess() async throws {
        let dispatcher = ScriptedRequestDispatcher(statuses: [503, 503, 200])
        let sut = HTTPRequestResolver(dispatcher: dispatcher)

        let result = try await sut.resolve(step(retry: retry(maxAttempts: 3, retryOn: [503])))

        XCTAssertEqual(dispatcher.dispatchCount, 3)
        XCTAssertEqual(result.outcome, .success)
    }

    func testDoesNotRetryUnlistedStatus() async throws {
        let dispatcher = ScriptedRequestDispatcher(statuses: [500, 200])
        let sut = HTTPRequestResolver(dispatcher: dispatcher)

        let result = try await sut.resolve(step(retry: retry(maxAttempts: 3, retryOn: [503])))

        XCTAssertEqual(dispatcher.dispatchCount, 1)
        XCTAssertEqual(result.outcome, .error)
    }

    func testEmptyRetryOnRetriesNothing() async throws {
        let dispatcher = ScriptedRequestDispatcher(statuses: [503, 200])
        let sut = HTTPRequestResolver(dispatcher: dispatcher)

        let result = try await sut.resolve(step(retry: retry(maxAttempts: 3, retryOn: [])))

        XCTAssertEqual(dispatcher.dispatchCount, 1)
        XCTAssertEqual(result.outcome, .error)
    }

    func testExhaustedAttemptsReturnLastResponse() async throws {
        let dispatcher = ScriptedRequestDispatcher(statuses: [503, 503])
        let sut = HTTPRequestResolver(dispatcher: dispatcher)

        let result = try await sut.resolve(step(retry: retry(maxAttempts: 2, retryOn: [503])))

        XCTAssertEqual(dispatcher.dispatchCount, 2)
        XCTAssertEqual(result.outcome, .error)

        guard case let .object(payload) = result.data else {
            return XCTFail("Expected a payload, got \(String(describing: result.data))")
        }
        XCTAssertEqual(payload["status"], .int(503))
    }

    // MARK: - Policy defaults

    func testDefaultsWhenPolicyAbsent() {
        let policy = HTTPRequestResolver.RetryPolicy()

        XCTAssertEqual(policy.maxAttempts, 1)
        XCTAssertEqual(policy.backoff, .exponential)
        XCTAssertEqual(policy.baseDelay, 0.25)
        XCTAssertTrue(policy.retryOn.isEmpty)
    }

    func testDefaultsSurviveAnIncompletePolicy() throws {
        let policy = try decodePolicy(.object(["retryOn": .array([.int(503)])]))

        XCTAssertEqual(policy.maxAttempts, 1)
        XCTAssertEqual(policy.backoff, .exponential)
        XCTAssertEqual(policy.baseDelay, 0.25)
        XCTAssertEqual(policy.retryOn, [503])
    }

    func testHostileValuesAreClamped() throws {
        let policy = try decodePolicy(
            .object(["maxAttempts": .int(0), "baseDelayMs": .int(-100)])
        )

        XCTAssertEqual(policy.maxAttempts, 1)
        XCTAssertEqual(policy.baseDelay, 0)
    }

    private func decodePolicy(_ value: CodableValue) throws -> HTTPRequestResolver.RetryPolicy {
        try value.casted(to: HTTPRequestResolver.RetryPolicy.self)
    }

    // MARK: - Backoff

    func testExponentialBackoffDoubles() {
        let policy = HTTPRequestResolver.RetryPolicy(backoff: .exponential, baseDelay: 1)

        assertDelay(policy.delay(after: 1), within: 1)
        assertDelay(policy.delay(after: 2), within: 2)
        assertDelay(policy.delay(after: 3), within: 4)
    }

    func testFixedBackoffDoesNotGrow() {
        let policy = HTTPRequestResolver.RetryPolicy(backoff: .fixed, baseDelay: 1)

        assertDelay(policy.delay(after: 1), within: 1)
        assertDelay(policy.delay(after: 5), within: 1)
    }

    func testBackoffIsCapped() {
        let policy = HTTPRequestResolver.RetryPolicy(backoff: .exponential, baseDelay: 1)

        assertDelay(policy.delay(after: 20), within: 30)
    }

    /// Every delay lands in `[maxWait/2, maxWait]`, so both halves are asserted at once.
    private func assertDelay(
        _ delay: TimeInterval,
        within maxWait: TimeInterval,
        line: UInt = #line
    ) {
        XCTAssertGreaterThanOrEqual(delay, maxWait / 2, line: line)
        XCTAssertLessThanOrEqual(delay, maxWait, line: line)
    }
}

// MARK: - Fixtures

private extension HTTPRequestResolverTests {

    func step(retry: CodableValue? = nil) -> CodableValue {
        var params: [String: CodableValue] = [
            "url": .string("https://example.com/pay"),
            "method": .string("POST")
        ]
        params["retry"] = retry
        return .object(params)
    }

    /// `baseDelayMs` is 1 throughout so the suite never really sleeps.
    func retry(maxAttempts: Int, retryOn: [Int]) -> CodableValue {
        .object([
            "maxAttempts": .int(maxAttempts),
            "baseDelayMs": .int(1),
            "retryOn": .array(retryOn.map(CodableValue.int))
        ])
    }
}

// MARK: - Mock

private final class ScriptedRequestDispatcher: RequestDispatcher, @unchecked Sendable {

    private(set) var dispatchCount = 0
    private var statuses: [Int]

    init(statuses: [Int]) {
        self.statuses = statuses
    }

    func dispatch(request: URLRequest) async throws -> DispatcherResponse {
        dispatchCount += 1
        guard !statuses.isEmpty else {
            XCTFail("Dispatched more times than the test scripted responses for")
            return response(status: 500)
        }
        return response(status: statuses.removeFirst())
    }

    private func response(status: Int) -> DispatcherResponse {
        DispatcherResponseModel(
            metadata: ResponseMetadataModel(responseUrl: nil, statusCode: status, headers: nil),
            requestDuration: 0,
            data: nil,
            error: nil
        )
    }

    // Unused by the resolver, which only ever takes the async path.

    func dispatch(request: URLRequest, completion: @escaping DispatcherCompletion) -> PrimerCancellable? {
        XCTFail("Unexpected completion-based dispatch")
        return nil
    }

    func dispatchWithRetry(
        request: URLRequest,
        retryConfig: RetryConfig,
        completion: @escaping DispatcherCompletion
    ) -> PrimerCancellable? {
        XCTFail("Unexpected dispatchWithRetry — the resolver runs its own loop")
        return nil
    }
}
