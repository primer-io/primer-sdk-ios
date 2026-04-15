//
//  PrimerStepOrchestratorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerBDCCore
import PrimerBDCEngine
import PrimerFoundation
import PrimerStepResolver
import XCTest

@MainActor
final class PrimerStepOrchestratorTests: XCTestCase {

    func testTerminalSuccess() async throws {
        try await startWith(terminal: "success")
    }

    func testTerminalCancelledCallsOnCancelled() async throws {
        let sut = makeSUT(startResult: terminal("cancelled"))
        let cancelled = expectation(description: "cancelled")
        sut.onCancelled = cancelled.fulfill
        
        try await sut.start(rawSchema: "{}", initialState: .object([:]))
        await fulfillment(of: [cancelled], timeout: 1)
    }

    func testTerminalErrorThrows() async {
        await assertStartThrows(terminal: "error")
    }

    func testTerminalUnsupportedThrows() async {
        await assertStartThrows(terminal: "unsupported")
    }

    func testLogActionDispatches() async throws {
        try await assertActionDispatches(actionType: StepDomain.platformLog)
    }

    func testHttpActionDispatches() async throws {
        try await assertActionDispatches(actionType: StepDomain.httpRequest)
    }

    func testNoResolverSendsUnsupported() async throws {
        let engine = MockBDCEngine()
        engine.startResult = action(type: "http.request")
        engine.applyResultResult = terminal("success")

        let sut = PrimerStepOrchestrator(engine: engine, context: stubContext, registry: PrimerStepResolverRegistry())
        try await sut.start(rawSchema: "{}", initialState: .object([:]))

        XCTAssertEqual(engine.lastApplyOutcome, "unsupported")
    }

    func testUnknownStepTypeSendsUnsupported() async throws {
        let engine = MockBDCEngine()
        engine.startResult = action(type: "future.new.step")
        engine.applyResultResult = terminal("success")

        let sut = PrimerStepOrchestrator(engine: engine, context: stubContext, registry: PrimerStepResolverRegistry())
        try await sut.start(rawSchema: "{}", initialState: .object([:]))

        XCTAssertEqual(engine.lastApplyOutcome, "unsupported")
    }

    func testEngineStartErrorWrapped() async {
        let engine = MockBDCEngine()
        engine.startError = Error.failed
        let sut = PrimerStepOrchestrator(engine: engine, context: stubContext)
        await XCTAssertThrowsErrorAsync { try await sut.start(rawSchema: "{}", initialState: .object([:])) }
    }
}

private extension PrimerStepOrchestratorTests {

    var stubContext: SDKContext {
        SDKContext(
            sdk: SDK(type: "IOS_NATIVE", version: "1.0", integrationType: "DROP_IN", paymentHandling: "AUTO"),
            device: SDKDevice(
                type: nil,
                make: "Apple",
                model: "iPhone",
                modelIdentifier: nil,
                platformVersion: "17.0",
                uniqueDeviceIdentifier: "test",
                locale: "en"
            ),
            app: SDKApp(identifier: "com.test"),
            session: SDKSession(checkoutSessionId: nil, clientSessionId: nil, customerId: nil),
            payment: SDKPayment(paymentMethodType: "PAYMENT_CARD"),
            merchant: SDKMerchant(primerAccountId: nil),
            analytics: SDKAnalytics(url: nil)
        )
    }

    func terminal(_ outcome: String) -> [String: Any] {
        [
            "newState": [:],
            "terminal": ["outcome": outcome]
        ]
    }

    func action(id: String = "a1", type: String, params: [String: Any] = [:]) -> [String: Any] {
        [
            "newState": [:],
            "action": ["id": id, "type": type, "params": params]
        ]
    }

    func makeSUT(startResult: [String: Any]) -> PrimerStepOrchestrator {
        let engine = MockBDCEngine()
        engine.startResult = startResult
        return PrimerStepOrchestrator(engine: engine, context: stubContext)
    }

    func startWith(terminal outcome: String) async throws {
        let sut = makeSUT(startResult: terminal(outcome))
        try await sut.start(rawSchema: "{}", initialState: .object([:]))
    }

    func assertStartThrows(terminal outcome: String, file: StaticString = #file, line: UInt = #line) async {
        let sut = makeSUT(startResult: terminal(outcome))
        await XCTAssertThrowsErrorAsync(file: file, line: line) {
            try await sut.start(rawSchema: "{}", initialState: .object([:]))
        }
    }

    func assertActionDispatches(
        actionType: String,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let engine = MockBDCEngine()
        let resolver = MockStepResolver()

        let registry = PrimerStepResolverRegistry()
        await registry.register(resolver, for: actionType)

        engine.startResult = action(type: actionType)
        engine.applyResultResult = terminal("success")

        let sut = PrimerStepOrchestrator(engine: engine, context: stubContext, registry: registry)
        try await sut.start(rawSchema: "{}", initialState: .object([:]))

        XCTAssertEqual(resolver.resolveCallCount, 1, file: file, line: line)
        XCTAssertEqual(engine.applyResultCallCount, 1, file: file, line: line)
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

private extension PrimerStepOrchestratorTests {
    enum Error: Swift.Error {
        case failed
    }
}
