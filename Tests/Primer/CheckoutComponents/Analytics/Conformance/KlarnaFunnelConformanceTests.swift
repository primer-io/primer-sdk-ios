//
//  KlarnaFunnelConformanceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
import XCTest

/// The exact events a Klarna payment sends through a real checkout, after the funnel rules.
@available(iOS 15.0, *)
@MainActor
final class KlarnaFunnelConformanceTests: XCTestCase {

    private typealias Sent = FunnelAnalyticsInteractor.Sent

    private let klarna = PrimerPaymentMethodType.klarna.rawValue
    private let funnel = FunnelAnalyticsInteractor()
    private let interactor = MockProcessKlarnaPaymentInteractor()
    private var sut: DefaultCheckoutScope!
    private var integrationType: PrimerSDKIntegrationType?

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
        integrationType = PrimerInternal.shared.sdkIntegrationType
        PrimerInternal.shared.sdkIntegrationType = .checkoutComponents
        interactor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        interactor.paymentResultToReturn = KlarnaTestData.successPaymentResult
    }

    override func tearDown() async throws {
        sut = nil
        PrimerInternal.shared.sdkIntegrationType = integrationType
        SDKSessionHelper.tearDown()
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_approvedAuthorization_sendsSubmittedThenSuccess() async throws {
        interactor.authorizationResultToReturn = .approved(authToken: KlarnaTestData.Constants.authToken)
        sut = try await makeSettledScope(paymentMethods: [Mocks.PaymentMethods.klarnaPaymentMethod])

        try await authorizeWithACategory(klarnaScope())

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, klarna, attempt: 1),
            Sent(.paymentProcessingStarted, klarna, attempt: 1),
            Sent(.paymentSubmitted, klarna, attempt: 1),
            Sent(.paymentSuccess, klarna, attempt: 1)
        ])
    }

    // Klarna reports a closed consent alert or sheet as declined, so the shopper left the method.
    func test_declinedAuthorization_sendsUnselectedWithoutSubmitted() async throws {
        interactor.authorizationResultToReturn = .declined
        sut = try await makeSettledScope(paymentMethods: [
            Mocks.PaymentMethods.klarnaPaymentMethod,
            Mocks.PaymentMethods.paymentCardPaymentMethod
        ])
        sut.paymentMethodSelection.onPaymentMethodSelected(
            paymentMethod: CheckoutPaymentMethod(id: klarna, type: klarna, name: "Klarna")
        )

        try await authorizeWithACategory(klarnaScope())

        try await funnel.waitFor(.paymentMethodUnselected)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, klarna, attempt: 1),
            Sent(.paymentProcessingStarted, klarna, attempt: 1),
            Sent(.paymentMethodUnselected, klarna, attempt: 1, reason: "shopper_cancel")
        ])
    }

    // A second method gives Klarna a list to return to, so closing it does not dismiss the checkout.
    func test_closingKlarna_sendsUnselectedShopperCancel() async throws {
        sut = try await makeSettledScope(paymentMethods: [
            Mocks.PaymentMethods.klarnaPaymentMethod,
            Mocks.PaymentMethods.paymentCardPaymentMethod
        ])
        sut.paymentMethodSelection.onPaymentMethodSelected(
            paymentMethod: CheckoutPaymentMethod(id: klarna, type: klarna, name: "Klarna")
        )
        let scope = try klarnaScope()
        _ = try await awaitValue(scope.state, matching: { $0.step == .categorySelection })
        try await funnel.waitFor(.paymentMethodSelection)

        scope.cancel()

        try await funnel.waitFor(.paymentMethodUnselected)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, klarna, attempt: 1),
            Sent(.paymentMethodUnselected, klarna, attempt: 1, reason: "shopper_cancel")
        ])
    }

    func test_retryAfterAFailedAuthorization_opensASecondAttempt() async throws {
        interactor.authorizeError = PrimerError.klarnaError(message: "Klarna rejected the purchase")
        sut = try await makeSettledScope(paymentMethods: [Mocks.PaymentMethods.klarnaPaymentMethod])
        try await authorizeWithACategory(klarnaScope())
        try await funnel.waitFor(.paymentFailure)

        interactor.authorizeError = nil
        interactor.authorizationResultToReturn = .approved(authToken: KlarnaTestData.Constants.authToken)
        sut.retryPayment()
        try await authorizeWithACategory(klarnaScope())

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, klarna, attempt: 1),
            Sent(.paymentProcessingStarted, klarna, attempt: 1),
            Sent(.paymentFailure, klarna, attempt: 1),
            Sent(.paymentReattempted, klarna, attempt: 2),
            Sent(.paymentProcessingStarted, klarna, attempt: 2),
            Sent(.paymentSubmitted, klarna, attempt: 2),
            Sent(.paymentSuccess, klarna, attempt: 2)
        ])
    }

    // MARK: - Helpers

    private func klarnaScope() throws -> DefaultKlarnaScope {
        let scope: DefaultKlarnaScope? = sut.getPaymentMethodScope(for: .klarna)
        return try XCTUnwrap(scope)
    }

    private func authorizeWithACategory(_ scope: DefaultKlarnaScope) async throws {
        _ = try await awaitValue(scope.state, matching: { $0.step == .categorySelection })
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        _ = try await awaitValue(scope.state, matching: { $0.step == .viewReady })
        scope.authorizePayment()
    }

    private func makeSettledScope(paymentMethods: [PrimerPaymentMethod]) async throws -> DefaultCheckoutScope {
        SDKSessionHelper.setUp(withPaymentMethods: paymentMethods)
        let container = try await ContainerTestHelpers.createTestContainer(
            apiConfiguration: PrimerAPIConfigurationModule.apiConfiguration,
            analyticsInteractor: funnel
        )
        _ = try await container.register(ProcessKlarnaPaymentInteractor.self)
            .asSingleton()
            .with { [interactor] _ in interactor }
        await DIContainer.setContainer(container)

        let scope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(uiOptions: PrimerUIOptions(isInitScreenEnabled: false)),
            navigator: CheckoutNavigator(coordinator: CheckoutCoordinator())
        )
        // Before any await: the init skips Klarna without PrimerKlarnaSDK, and its methods load once this test yields.
        KlarnaPaymentMethod.register()
        for _ in 0 ..< 200 {
            if case .initializing = scope.currentState {} else {
                try await funnel.waitFor(.checkoutFlowStarted)
                return scope
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        throw TestError.timeout
    }
}
