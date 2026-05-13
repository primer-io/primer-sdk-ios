//
//  BackendDrivenCheckoutViewModelTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) import PrimerFoundation
@testable import PrimerSDK
import XCTest

@MainActor
final class BackendDrivenCheckoutViewModelTests: XCTestCase {
    
    private var uiManager: MockPrimerUIManager!
    private var delegate: MockPrimerHeadlessUniversalCheckoutDelegate!
    private var mockOrchestrator: MockBDCStepOrchestrator!
    
    private let payment = PaymentInfo(id: "pay_1", orderId: "ord_1", status: "SUCCESS")
    private let failedPayment = PaymentInfo(id: "pay_1", orderId: "ord_1", status: "FAILED")
    
    override func setUp() {
        super.setUp()
        SDKSessionHelper.setUp(withPaymentMethods: [stubConfig])
        delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        
        delegate.onWillCreatePaymentWithData = { data, decision in
            decision(.continuePaymentCreation())
        }
        
        PrimerHeadlessUniversalCheckout.current.delegate = delegate
        uiManager = MockPrimerUIManager()
        uiManager.primerRootViewController = MockPrimerRootViewController()
        mockOrchestrator = MockBDCStepOrchestrator()
    }
    
    override func tearDown() {
        PrimerHeadlessUniversalCheckout.current.delegate = nil
        SDKSessionHelper.tearDown()
        super.tearDown()
    }
    
    func testSuccessOutcomeCallsComplete() {
        assertComplete {
            makeSUT(instructions: [.end(outcome: .complete, payment: payment)])
        }
    }
    
    func testExecuteThenEndCompletes() {
        assertComplete {
            makeSUT(instructions: [
                .execute(delayMilliseconds: 0, schema: .object([:]), parameters: .object([:])),
                .end(outcome: .complete, payment: nil)
            ])
        }
    }
    
    func testFailureOutcomeCallsDidFail() {
        let errorToMatch: (Swift.Error) -> Bool = {
            guard case PrimerError.paymentFailed = $0 else { return false }
            return true
        }
        assertDidFail(matching: errorToMatch) {
            makeSUT(instructions: [.end(outcome: .failure, payment: failedPayment)])
        }
    }
    
    func testNilOutcomeCallsDidFail() {
        assertDidFail { makeSUT(instructions: [.end(outcome: nil, payment: nil)]) }
    }
    
    func testOrchestratorCreationFailureCallsDidFail() {
        assertDidFail { makeSUT(makeOrchestrator: { _ in throw Error.orchestratorFailed }) }
    }
    
    func testInstructionProviderErrorCallsDidFail() {
        let provider = MockBDCInstructionProvider([])
        provider.error = Error.providerFailed
        assertDidFail { makeSUT(makeInstructionProvider: { _ in provider })}
    }
    
    func testOnCancelledCallsDidFailWithCancellation() {
        let errorToMatch: (Swift.Error) -> Bool = {
            guard case PrimerError.cancelled = $0 else { return false }
            return true
        }
        assertDidFail(matching: errorToMatch) {
            let sut = makeSUT(instructions: [
                .execute(delayMilliseconds: 0, schema: .object([:]), parameters: .object([:]))
            ])
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.mockOrchestrator.onCancelled?() }
            return sut
        }
    }
}

private extension BackendDrivenCheckoutViewModelTests {
    
    var stubConfig: PrimerPaymentMethod {
        PrimerPaymentMethod(
            id: "mock_bdc_id", implementationType: .nativeSdk,
            type: "MOCK_BDC", name: "Mock BDC",
            processorConfigId: "pid", surcharge: nil, options: nil, displayMetadata: nil
        )
    }
    
    func makeSUT(
        instructions: [ClientInstruction] = [],
        makeOrchestrator: BackendDrivenCheckoutViewModel.OrchestratorFactory? = nil,
        makeInstructionProvider: BackendDrivenCheckoutViewModel.InstructionProviderFactory? = nil
    ) -> BackendDrivenCheckoutViewModel {
        BackendDrivenCheckoutViewModel(
            config: stubConfig,
            uiManager: uiManager,
            tokenizationService: MockTokenizationService(),
            createResumePaymentService: MockCreateResumePaymentService(),
            makeOrchestrator: makeOrchestrator ?? { [mockOrchestrator] _ in
                BackendDrivenCheckoutOrchestrator(stepOrchestrator: mockOrchestrator!)
            },
            makeInstructionProvider: makeInstructionProvider ?? { _ in
                MockBDCInstructionProvider(instructions)
            }
        )
    }
    
    func assertComplete(
        timeout: TimeInterval = 5.0,
        file: StaticString = #file, line: UInt = #line,
        _ makeSUT: () -> BackendDrivenCheckoutViewModel
    ) {
        let exp = expectation(description: "complete")
        delegate.onDidCompleteCheckoutWithData = { _ in exp.fulfill() }
        makeSUT().start()
        wait(for: [exp], timeout: timeout)
    }
    
    func assertDidFail(
        matching predicate: ((Swift.Error) -> Bool)? = nil,
        timeout: TimeInterval = 3.0,
        file: StaticString = #file, line: UInt = #line,
        _ makeSUT: () -> BackendDrivenCheckoutViewModel
    ) {
        let exp = expectation(description: "fail")
        delegate.onDidFail = { error in
            if let predicate, !predicate(error) {
                XCTFail("Error did not match predicate: \(error)", file: file, line: line)
            }
            exp.fulfill()
        }
        makeSUT().start()
        wait(for: [exp], timeout: timeout)
    }
}

private extension BackendDrivenCheckoutViewModelTests {
    enum Error: Swift.Error {
        case orchestratorFailed
        case providerFailed
    }
}

@MainActor
private final class MockBDCStepOrchestrator: StepOrchestrating {
    var onURLOpen: (() -> Void)?
    var onCancelled: (() -> Void)?
    var startCallCount = 0
    var startError: Error?
    
    func start(rawSchema: String, initialState: CodableValue) async throws {
        startCallCount += 1
        if let startError { throw startError }
    }
}

private final class MockBDCInstructionProvider: ClientInstructionProvider {
    var error: Error?
    private var instructions: [ClientInstruction]
    private var index = 0
    
    init(_ instructions: [ClientInstruction]) { self.instructions = instructions }
    
    func fetchPayInstruction() async throws -> ClientInstruction { try next() }
    func fetchNextInstruction() async throws -> ClientInstruction { try next() }
    
    private func next() throws -> ClientInstruction {
        if let error { throw error }
        guard index < instructions.count else { return .wait(delayMilliseconds: 0) }
        defer { index += 1 }
        return instructions[index]
    }
}
