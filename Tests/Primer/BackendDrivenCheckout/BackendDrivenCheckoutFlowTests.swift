//
//  BackendDrivenCheckoutFlowTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerSDK
import XCTest

@MainActor
final class BackendDrivenCheckoutFlowTests: XCTestCase {
    private let payment = PaymentInfo(id: "pay_1", orderId: "ord_1", status: "SUCCESS")
    private var provider: MockBDCInstructionProvider!
    private var analyticsService: Analytics.Service!

    override func setUp() async throws {
        try await super.setUp()
        SDKSessionHelper.setUp()
        provider = MockBDCInstructionProvider([.end(outcome: .complete, payment: payment)])
        provider.setupCompleteToken = "tok_setup"
        analyticsService = Analytics.Service.shared
        Analytics.Service.shared = Analytics.Service(
            sdkLogsUrl: URL(string: "http://localhost/")!,
            batchSize: 1000,
            storage: MockAnalyticsStorage(),
            apiClient: MockPrimerAPIAnalyticsClient()
        )
    }

    override func tearDown() async throws {
        Analytics.Service.shared = analyticsService
        DependencyContainer.register(PrimerSettings() as PrimerSettingsProtocol)
        SDKSessionHelper.tearDown()
        try await super.tearDown()
    }

    func testASetupFlowPaysWithItsTokenUnderManualHandling() async throws {
        DependencyContainer.register(PrimerSettings(paymentHandling: .manual) as PrimerSettingsProtocol)
        let sut = try makeSUT()

        let outcome = await sut.run(host: host())

        guard case let .paid(paid) = outcome else { return XCTFail("Expected a payment, got \(outcome)") }
        XCTAssertEqual(paid, payment)
        XCTAssertEqual(provider.paidWithTokenIds, ["tok_setup"])
    }

    func testTheMerchantIsAskedAfterSetupAndBeforePaying() async throws {
        let sut = try makeSUT()
        var setupFetchesWhenAsked: Int?
        var paymentsWhenAsked: Int?

        _ = await sut.run(host: host(willCreatePayment: { [provider] in
            setupFetchesWhenAsked = provider?.setupFlowFetches
            paymentsWhenAsked = provider?.paidWithTokenIds.count
        }))

        XCTAssertEqual(setupFetchesWhenAsked, 1)
        XCTAssertEqual(paymentsWhenAsked, 0)
        XCTAssertEqual(provider.paidWithTokenIds, ["tok_setup"])
    }

    func testAMerchantAbortAfterSetupFailsWithoutPaying() async throws {
        let sut = try makeSUT()

        let outcome = await sut.run(host: host(willCreatePayment: {
            throw PrimerError.merchantError(message: "no")
        }))

        guard case let .failed(error) = outcome, case PrimerError.merchantError = error else {
            return XCTFail("Expected a merchant error, got \(outcome)")
        }
        XCTAssertEqual(provider.paidWithTokenIds, [])
    }

    private func makeSUT() throws -> BackendDrivenCheckoutFlow {
        let config = try JSONDecoder().decode(PrimerPaymentMethod.self, from: Data("""
        {"id": "mock_bdc_id", "implementationType": "NATIVE_SDK", "type": "MOCK_BDC", "name": "Mock BDC", "setupStart": "ON_SELECT"}
        """.utf8))
        XCTAssertTrue(config.entry.requiresSetup)
        let stepOrchestrator = MockBDCStepOrchestrator()
        stepOrchestrator.pollsReturn = true
        return BackendDrivenCheckoutFlow(
            config: config,
            makeOrchestrator: { _ in BackendDrivenCheckoutOrchestrator(stepOrchestrator: stepOrchestrator) },
            makeInstructionProvider: { [provider] _ in provider! }
        )
    }

    private func host(
        willCreatePayment: @escaping @MainActor () async throws -> Void = {}
    ) -> BackendDrivenCheckoutFlow.Host {
        BackendDrivenCheckoutFlow.Host(willCreatePayment: willCreatePayment, presentUI: { true }, dismissUI: {})
    }
}
