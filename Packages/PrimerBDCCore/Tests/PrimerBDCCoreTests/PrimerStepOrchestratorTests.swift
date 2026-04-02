//
//  PrimerStepOrchestratorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerBDCCore
import PrimerFoundation
import PrimerStepResolver
import XCTest

@MainActor
final class PrimerStepOrchestratorTests: XCTestCase {

    private var mockEngine: MockBDCEngine!
    private var registry: PrimerStepResolverRegistry!
    private let state: CodableValue = .object([:])

    override func setUp() {
        mockEngine = MockBDCEngine()
        registry = PrimerStepResolverRegistry()
    }

    override func tearDown() {
        mockEngine = nil
        registry = nil
    }

    // MARK: - Terminal outcomes

    func testTerminalCancelledCallsOnCancelled() async throws {
        mockEngine.startResult = terminalResponse(outcome: "cancelled")
        let orchestrator = PrimerStepOrchestrator(engine: mockEngine, registry: registry)
        let expectation = expectation(description: "onCancelled called")
        orchestrator.onCancelled = { expectation.fulfill() }
        try await orchestrator.start(rawSchema: "{}", context: context, initialState: state)
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testTerminalSuccessDoesNotCallOnCancelled() async throws {
        mockEngine.startResult = terminalResponse(outcome: "success")
        let orchestrator = PrimerStepOrchestrator(engine: mockEngine, registry: registry)
        orchestrator.onCancelled = { XCTFail("onCancelled should not be called for success") }
        try await orchestrator.start(rawSchema: "{}", context: context, initialState: state)
    }

    func testTerminalErrorDoesNotCallOnCancelled() async throws {
        mockEngine.startResult = terminalResponse(outcome: "error")
        let orchestrator = PrimerStepOrchestrator(engine: mockEngine, registry: registry)
        orchestrator.onCancelled = { XCTFail("onCancelled should not be called for error") }
        try await orchestrator.start(rawSchema: "{}", context: context, initialState: state)
    }

    func testLogActionRoutesToAnalyticsHandler() async throws {
        try await assertActionRoutes(to: .platformLog, actionType: "platform.log")
    }

    func testHttpActionRoutesToHTTPHandler() async throws {
        try await assertActionRoutes(to: .httpRequest, actionType: "http.request")
    }

    func testEngineStartFailureThrows() async {
        do {
            mockEngine.startError = NSError(domain: "test", code: 42)
            let orchestrator = PrimerStepOrchestrator(engine: mockEngine, registry: registry)
            try await orchestrator.start(rawSchema: "{}", context: context, initialState: state)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected
        }
    }

    func testStateIsUpdatedFromEngineResponse() async throws {
        let mockResolver = MockStepResolver()
        await registry.register(mockResolver, forStepType: .platformLog)
        let response = actionResponse(id: "a1", type: "platform.log", params: [:], state: ["token": "abc123"])
        mockEngine.startResult = response
        mockEngine.applyResultResult = terminalResponse(outcome: "success")
        let orchestrator = PrimerStepOrchestrator(engine: mockEngine, registry: registry)
        try await orchestrator.start(rawSchema: "{}", context: context, initialState: state)

        XCTAssertNotNil(mockEngine.lastApplyResultState)
    }
}

// MARK: - Helpers

@MainActor
private extension PrimerStepOrchestratorTests {
    var context: SDKContext {
        SDKContext(
            sdk: SDK(type: "IOS", version: "1.0", integrationType: "DROP_IN", paymentHandling: "AUTO"),
            device: SDKDevice(type: "phone", make: "Apple", model: "Test", modelIdentifier: nil, platformVersion: "17.0", uniqueDeviceIdentifier: "test-id", locale: "en"),
            app: SDKApp(identifier: "com.test"),
            session: SDKSession(checkoutSessionId: nil, clientSessionId: nil, customerId: nil),
            payment: SDKPayment(paymentMethodType: "CARD"),
            merchant: SDKMerchant(primerAccountId: nil),
            analytics: SDKAnalytics(url: nil)
        )
    }

    func assertActionRoutes(
        to domain: StepDomain,
        actionType: String,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let mockResolver = MockStepResolver()
        await registry.register(mockResolver, forStepType: domain)

        mockEngine.startResult = actionResponse(id: "action-1", type: actionType, params: [:])
        mockEngine.applyResultResult = terminalResponse(outcome: "success")

        let orchestrator = PrimerStepOrchestrator(engine: mockEngine, registry: registry)
        try await orchestrator.start(rawSchema: "{}", context: context, initialState: state)

        XCTAssertTrue(
            mockResolver.resolveCalled,
            "\(domain.rawValue) resolver should have been called",
            file: file,
            line: line
        )
    }

    func terminalResponse(outcome: String) -> AnyDict {
        [
            "newState": [String: Any](),
            "terminal": ["outcome": outcome]
        ]
    }

    func actionResponse(
        id: String,
        type: String,
        params: [String: Any],
        state: [String: Any] = [:]
    ) -> AnyDict {
        [
            "newState": state,
            "action": ["id": id, "type": type, "params": params]
        ]
    }
}
