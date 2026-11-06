//
//  CheckoutFunnelConformanceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
import XCTest

/// The exact events a real checkout sends, after the funnel rules, for the cases every payment method shares.
@available(iOS 15.0, *)
@MainActor
final class CheckoutFunnelConformanceTests: XCTestCase {

    private typealias Sent = FunnelAnalyticsInteractor.Sent

    private let card = PrimerPaymentMethodType.paymentCard.rawValue
    private let ideal = Mocks.PaymentMethods.adyenIDealPaymentMethod
    private let funnel = FunnelAnalyticsInteractor()
    private let repository = MockWebRedirectRepository()
    private var sut: DefaultCheckoutScope!
    private var integrationType: PrimerSDKIntegrationType?

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
        // The shared core asks the merchant before it creates a payment, and only CheckoutComponents answers itself.
        integrationType = PrimerInternal.shared.sdkIntegrationType
        PrimerInternal.shared.sdkIntegrationType = .checkoutComponents
    }

    override func tearDown() async throws {
        sut = nil
        PrimerInternal.shared.sdkIntegrationType = integrationType
        SDKSessionHelper.tearDown()
        DependencyContainer.register(PrimerSettings() as PrimerSettingsProtocol)
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_checkoutThatFailsToLoad_sendsNoPaymentEvent() async throws {
        sut = try await makeSettledScope(paymentMethods: [])

        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [])
    }

    func test_onlyMethodOpenedByTheCheckout_isSelectedAndPaid() async throws {
        repository.resumePaymentResult = .success(PaymentResult(paymentId: "pay_1", status: .success, paymentMethodType: ideal.type))
        sut = try await makeSettledScope(paymentMethods: [ideal])

        try await funnel.waitFor(.paymentSuccess)
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, ideal.type, attempt: 1),
            Sent(.paymentProcessingStarted, ideal.type, attempt: 1),
            Sent(.paymentRedirectToThirdParty, ideal.type, attempt: 1),
            Sent(.paymentReturnedFromThirdParty, ideal.type, attempt: 1),
            Sent(.paymentSubmitted, ideal.type, attempt: 1),
            Sent(.paymentSuccess, ideal.type, attempt: 1)
        ])
        let redirect = await funnel.outputs.first { $0.eventType == .paymentRedirectToThirdParty }
        XCTAssertEqual(redirect?.metadata?.paymentId, "mock_payment_id")
    }

    // A merchant's own pay button submits again without the SDK's retry.
    func test_resubmitAfterAFailure_thatTheMerchantAborts_isANewAttempt() async throws {
        sut = try await makeSettledScope(paymentMethods: [Mocks.PaymentMethods.paymentCardPaymentMethod])
        try await sut.invokeBeforePaymentCreate(paymentMethodType: card)
        sut.handlePaymentError(paymentFailed())
        try await funnel.waitFor(.paymentFailure)

        sut.onBeforePaymentCreate = { _, decide in decide(.abortPaymentCreation(withErrorMessage: nil)) }
        do {
            try await sut.invokeBeforePaymentCreate(paymentMethodType: card)
        } catch let error as PrimerError {
            sut.handlePaymentError(error)
        }

        try await funnel.waitFor(.paymentMethodUnselected)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, card, attempt: 1),
            Sent(.paymentFailure, card, attempt: 1),
            Sent(.paymentReattempted, card, attempt: 2),
            Sent(.paymentMethodUnselected, card, attempt: 2, reason: "merchant_abort")
        ])
    }

    func test_closingTheInlineSheetWhileThePaymentRuns_keepsItsOutcome() async throws {
        sut = try await makeSettledScope(paymentMethods: [Mocks.PaymentMethods.paymentCardPaymentMethod], isInlineFlow: true)
        try await sut.invokeBeforePaymentCreate(paymentMethodType: card)
        sut.startProcessing(payingWith: nil)

        sut.cancelActivePaymentMethod(returnToSelection: true, abandonsMethod: false)
        sut.handlePaymentSuccess(PaymentResult(paymentId: "pay_1", status: .success, paymentMethodType: card))

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, card, attempt: 1),
            Sent(.paymentSuccess, card, attempt: 1)
        ])
    }

    // MARK: - Helpers

    private func paymentFailed() -> PrimerError {
        .paymentFailed(paymentMethodType: card, paymentId: "pay_1", orderId: nil, status: "DECLINED", diagnosticsId: "diag")
    }

    private func makeSettledScope(
        paymentMethods: [PrimerPaymentMethod],
        isInlineFlow: Bool = false
    ) async throws -> DefaultCheckoutScope {
        SDKSessionHelper.setUp(withPaymentMethods: paymentMethods)
        // A redirect needs a return URL scheme.
        DependencyContainer.register(
            PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "testapp://payment")) as PrimerSettingsProtocol
        )
        let container = try await ContainerTestHelpers.createTestContainer(
            apiConfiguration: PrimerAPIConfigurationModule.apiConfiguration,
            analyticsInteractor: funnel
        )
        let interactor = ProcessWebRedirectPaymentInteractorImpl(
            repository: repository,
            clientSessionActionsFactory: { MockClientSessionActionsModule() },
            deeplinkAbilityProvider: MockDeeplinkAbilityProvider(),
            analytics: funnel
        )
        _ = try await container.register(ProcessWebRedirectPaymentInteractor.self)
            .asSingleton()
            .with { _ in interactor }
        _ = try await container.register(WebRedirectRepository.self)
            .asSingleton()
            .with { [repository] _ in repository }
        await DIContainer.setContainer(container)

        let scope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(uiOptions: PrimerUIOptions(isInitScreenEnabled: false)),
            navigator: CheckoutNavigator(coordinator: CheckoutCoordinator()),
            isInlineFlow: isInlineFlow
        )
        for _ in 0 ..< 200 {
            if case .initializing = scope.currentState {} else { return scope }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        throw TestError.timeout
    }
}
