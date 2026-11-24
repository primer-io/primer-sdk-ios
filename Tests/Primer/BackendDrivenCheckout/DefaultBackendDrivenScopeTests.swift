//
//  DefaultBackendDrivenScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerSDK
import XCTest

@available(iOS 16.0, *)
@MainActor
final class DefaultBackendDrivenScopeTests: XCTestCase {
    private let payment = PaymentInfo(id: "pay_1", orderId: "ord_1", status: "SUCCESS")
    private let config = PrimerPaymentMethod(
        id: "mock_bdc_id", implementationType: .nativeSdk,
        type: "MOCK_BDC", name: "Mock BDC",
        processorConfigId: "pid", surcharge: nil, options: nil, displayMetadata: nil
    )
    private var checkoutScope: DefaultCheckoutScope!

    override func setUp() async throws {
        try await super.setUp()
        SDKSessionHelper.setUp(withPaymentMethods: [config])
        checkoutScope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            navigator: CheckoutNavigator(coordinator: CheckoutCoordinator())
        )
        let checkoutScope = checkoutScope!
        try await withTimeout(3.0) {
            while checkoutScope.navigationState == .loading { await Task.yield() }
        }
    }

    override func tearDown() async throws {
        checkoutScope = nil
        SDKSessionHelper.tearDown()
        try await super.tearDown()
    }

    func testACompletedFlowReportsSuccessToTheCheckout() async throws {
        let sut = makeSUT(MockBDCInstructionProvider([.end(outcome: .complete, payment: payment)]))

        sut.start()

        let result = try await awaitSuccess()
        XCTAssertEqual(result.paymentId, "pay_1")
        XCTAssertEqual(result.paymentMethodType, "MOCK_BDC")
    }

    func testAFailedFlowReportsTheFailureToTheCheckout() async throws {
        let failed = PaymentInfo(id: "pay_1", orderId: "ord_1", status: "FAILED")
        let sut = makeSUT(MockBDCInstructionProvider([.end(outcome: .failure, payment: failed)]))

        sut.start()

        let checkoutScope = checkoutScope!
        try await withTimeout(3.0) {
            while true {
                if case .failure = checkoutScope.navigationState { return }
                await Task.yield()
            }
        }
    }

    func testASavedMethodPaysWithItsTokenAndSkipsSetup() async throws {
        let provider = MockBDCInstructionProvider([.end(outcome: .complete, payment: payment)])
        let sut = makeSUT(provider)

        sut.start(paymentInstrumentTokenId: "tok_1")

        _ = try await awaitSuccess()
        XCTAssertEqual(provider.paidWithTokenIds, ["tok_1"])
        XCTAssertEqual(provider.setupFlowFetches, 0)
    }

    private func makeSUT(_ provider: MockBDCInstructionProvider) -> DefaultBackendDrivenScope {
        DefaultBackendDrivenScope(
            paymentMethodType: config.type,
            checkoutScope: checkoutScope,
            makeFlow: { config in
                BackendDrivenCheckoutFlow(
                    config: config,
                    makeOrchestrator: { _ in BackendDrivenCheckoutOrchestrator(stepOrchestrator: MockBDCStepOrchestrator()) },
                    makeInstructionProvider: { _ in provider }
                )
            }
        )
    }

    private func awaitSuccess() async throws -> PaymentResult {
        let checkoutScope = checkoutScope!
        return try await withTimeout(3.0) {
            while true {
                if case let .success(result) = checkoutScope.navigationState { return result }
                await Task.yield()
            }
        }
    }
}
