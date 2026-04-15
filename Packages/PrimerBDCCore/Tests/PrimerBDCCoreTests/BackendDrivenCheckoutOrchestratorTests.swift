//
//  BackendDrivenCheckoutOrchestratorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerBDCCore
import PrimerFoundation
import XCTest

@MainActor
final class BackendDrivenCheckoutOrchestratorTests: XCTestCase {

    private let payment = PaymentInfo(id: "pay_1", orderId: "ord_1", status: "SUCCESS")
    private let failedPayment = PaymentInfo(id: "pay_1", orderId: "ord_1", status: "FAILED")

    func testEndCompleteReturnsSuccess() async throws {
        try await assertRun(
            [.end(outcome: .complete, payment: payment)],
            returns: .success(payment: payment)
        )
    }

    func testEndFailureReturnsFailure() async throws {
        try await assertRun(
            [.end(outcome: .failure, payment: failedPayment)],
            returns: .failure(payment: failedPayment)
        )
    }

    func testDetermineFromPaymentStatusSuccess() async throws {
        try await assertRun(
            [.end(outcome: .determineFromPaymentStatus, payment: payment)],
            returns: .success(payment: payment)
        )
    }

    func testDetermineFromPaymentStatusFailed() async throws {
        try await assertRun(
            [.end(outcome: .determineFromPaymentStatus, payment: failedPayment)],
            returns: .failure(payment: failedPayment)
        )
    }

    func testNilOutcomeThrows() async {
        await assertRunThrows(
            [.end(outcome: nil, payment: nil)],
            mock: MockStepOrchestrator()
        )
    }

    func testDetermineNilPaymentThrows() async {
        await assertRunThrows(
            [.end(outcome: .determineFromPaymentStatus, payment: nil)],
            mock: MockStepOrchestrator()
        )
    }

    func testWaitThenEnd() async throws {
        try await assertRun(
            [.wait(delayMilliseconds: 0), .end(outcome: .complete, payment: nil)],
            returns: .success(payment: nil)
        )
    }

    func testExecuteThenEnd() async throws {
        let mock = MockStepOrchestrator()
        let result = try await run(
            mock: mock,
            instructions: [
                .execute(delayMilliseconds: 0, schema: .object([:]), parameters: .object([:])),
                .end(outcome: .complete, payment: nil),
            ]
        )

        XCTAssertEqual(result, .success(payment: nil))
        XCTAssertEqual(mock.startCallCount, 1)
    }

    func testExecuteErrorPropagates() async {
        let mock = MockStepOrchestrator()
        mock.startError = Error.failed

        await assertRunThrows(
            [.execute(delayMilliseconds: 0, schema: .object([:]), parameters: .object([:]))],
            mock: mock
        )
    }

    func testOnCancelledForwards() {
        let mock = MockStepOrchestrator()
        let sut = BackendDrivenCheckoutOrchestrator(stepOrchestrator: mock)
        var called = false
        sut.onCancelled = { called = true }

        mock.onCancelled?()

        XCTAssertTrue(called)
    }

    func testProviderErrorPropagates() async {
        let provider = MockInstructionProvider([])
        provider.error = Error.failed

        let sut = BackendDrivenCheckoutOrchestrator(stepOrchestrator: MockStepOrchestrator())
        await XCTAssertThrowsErrorAsync { try await sut.run(instructionProvider: provider) }
    }
}

private extension BackendDrivenCheckoutOrchestratorTests {

    func assertRun(
        _ instructions: [ClientInstruction],
        returns expected: CheckoutResult,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let result = try await run(mock: MockStepOrchestrator(), instructions: instructions)
        XCTAssertEqual(result, expected, file: file, line: line)
    }

    func assertRunThrows(
        _ instructions: [ClientInstruction],
        mock: MockStepOrchestrator,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        await XCTAssertThrowsErrorAsync(file: file, line: line) {
            try await run(mock: mock, instructions: instructions)
        }
    }

    @discardableResult
    func run(mock: MockStepOrchestrator, instructions: [ClientInstruction]) async throws -> CheckoutResult {
        let sut = BackendDrivenCheckoutOrchestrator(stepOrchestrator: mock)
        return try await sut.run(instructionProvider: MockInstructionProvider(instructions))
    }

    func XCTAssertThrowsErrorAsync(
        file: StaticString = #file, line: UInt = #line,
        _ expression: () async throws -> some Any
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error", file: file, line: line) } catch {

        }
    }
}

private extension BackendDrivenCheckoutOrchestratorTests {
    enum Error: Swift.Error {
        case failed
    }
}
