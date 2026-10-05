//
//  BackendDrivenSetupRepositoryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation

@available(iOS 15.0, *)
@MainActor
final class BackendDrivenSetupRepositoryTests: XCTestCase {

    private var api: MockPaymentMethodSetupAPI!
    private var runner: MockSetupScreenRunner!

    override func setUp() {
        super.setUp()
        api = MockPaymentMethodSetupAPI()
        runner = MockSetupScreenRunner()
    }

    override func tearDown() {
        api = nil
        runner = nil
        super.tearDown()
    }

    func test_setUp_runsTheScreenPollsAndReturnsTheToken() async throws {
        api.startResponse = .execute
        api.pollResponses = [.wait(.interval), .complete(token: "multi_use_token")]

        let token = try await makeSut().setUp(paymentMethodType: "KLARNA", intent: .vault)

        XCTAssertEqual(token, "multi_use_token")
        XCTAssertEqual(runner.runCount, 1)
        XCTAssertEqual(api.startCalls.map(\.intent), [.vault])
        XCTAssertEqual(api.startCalls.map(\.paymentMethodConfigId), ["config-KLARNA"])
        XCTAssertEqual(api.pollCalls, ["pms_1", "pms_1"])
    }

    func test_setUp_completeWithoutToken_throws() async {
        api.startResponse = .complete(token: nil)

        await assertSetUpThrows(.missingToken)
    }

    func test_setUp_executeWithoutScreen_throws() async {
        api.startResponse = response(.execute, payload: nil)

        await assertSetUpThrows(.missingScreen)
    }

    func test_setUp_waitThatSuspends_failsInsteadOfPolling() async {
        api.startResponse = .execute
        api.pollResponses = [.wait(.suspend)]

        await assertSetUpThrows(.suspended)
        XCTAssertEqual(api.pollCalls.count, 1)
    }

    func test_setUp_endlessWait_timesOut() async {
        api.startResponse = .wait(.interval)
        api.repeatsLastPoll = true
        api.pollResponses = [.wait(.interval)]

        await assertSetUpThrows(.timedOut)
        XCTAssertEqual(api.pollCalls.count, BackendDrivenSetupRepositoryImpl.maxConsecutiveWaits)
    }

    func test_setUp_pollFailure_propagates() async {
        api.startResponse = .execute
        api.pollError = TestError.networkFailure

        do {
            _ = try await makeSut().setUp(paymentMethodType: "KLARNA", intent: .vault)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
        }
    }

    func test_setUp_screenFailure_propagatesWithoutPolling() async {
        api.startResponse = .execute
        runner.error = TestError.networkFailure

        do {
            _ = try await makeSut().setUp(paymentMethodType: "KLARNA", intent: .vault)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
        }
        XCTAssertTrue(api.pollCalls.isEmpty)
    }

    // MARK: - Helpers

    private func makeSut() -> BackendDrivenSetupRepositoryImpl {
        BackendDrivenSetupRepositoryImpl(api: api, screenRunner: runner) { "config-\($0)" }
    }

    private func assertSetUpThrows(
        _ expected: BackendDrivenSetupError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await makeSut().setUp(paymentMethodType: "KLARNA", intent: .vault)
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? BackendDrivenSetupError, expected, file: file, line: line)
        }
    }
}

// MARK: - Fixtures

private func response(
    _ type: PaymentMethodSetupResponse.Kind,
    nextPoll: PaymentMethodSetupResponse.NextPoll? = nil,
    payload: String? = #"{"schema": {}, "parameters": {}}"#,
    token: String? = nil
) -> PaymentMethodSetupResponse {
    var instruction = #""type": "\#(type.rawValue)", "pollDelayMilliseconds": 0"#
    if let nextPoll { instruction += #", "nextPoll": "\#(nextPoll.rawValue)""# }
    if let payload, type == .execute { instruction += #", "payload": \#(payload)"# }
    if let token { instruction += #", "paymentInstrumentToken": {"token": "\#(token)"}"# }
    let json = #"{"paymentMethodSetupId": "pms_1", "instruction": {\#(instruction)}}"#
    // swiftlint:disable:next force_try
    return try! JSONDecoder().decode(PaymentMethodSetupResponse.self, from: Data(json.utf8))
}

private extension PaymentMethodSetupResponse {
    static var execute: PaymentMethodSetupResponse { response(.execute, nextPoll: .suspend) }
    static func wait(_ nextPoll: NextPoll) -> PaymentMethodSetupResponse { response(.wait, nextPoll: nextPoll) }
    static func complete(token: String?) -> PaymentMethodSetupResponse { response(.setupComplete, token: token) }
}

@available(iOS 15.0, *)
private final class MockPaymentMethodSetupAPI: PaymentMethodSetupAPI {
    var startResponse: PaymentMethodSetupResponse?
    var pollResponses: [PaymentMethodSetupResponse] = []
    var repeatsLastPoll = false
    var pollError: Error?
    private(set) var startCalls: [(paymentMethodConfigId: String?, intent: PrimerSessionIntent)] = []
    private(set) var pollCalls: [String] = []

    func start(paymentMethodConfigId: String?, intent: PrimerSessionIntent) async throws -> PaymentMethodSetupResponse {
        startCalls.append((paymentMethodConfigId, intent))
        guard let startResponse else { throw TestError.unknown }
        return startResponse
    }

    func poll(setupId: String) async throws -> PaymentMethodSetupResponse {
        pollCalls.append(setupId)
        if let pollError { throw pollError }
        if repeatsLastPoll, pollResponses.count == 1 { return pollResponses[0] }
        guard !pollResponses.isEmpty else { throw TestError.unknown }
        return pollResponses.removeFirst()
    }
}

@available(iOS 15.0, *)
private final class MockSetupScreenRunner: SetupScreenRunning {
    var error: Error?
    private(set) var runCount = 0

    func run(_ screen: PaymentMethodSetupResponse.Screen, paymentMethodType: String) async throws {
        runCount += 1
        if let error { throw error }
    }
}
