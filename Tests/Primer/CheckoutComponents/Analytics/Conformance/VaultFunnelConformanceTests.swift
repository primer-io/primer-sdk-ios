//
//  VaultFunnelConformanceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerNetworking
import XCTest

/// The exact events a real checkout sends, after the funnel rules, when the shopper pays with a saved method.
@available(iOS 15.0, *)
@MainActor
final class VaultFunnelConformanceTests: XCTestCase {

    private typealias Sent = FunnelAnalyticsInteractor.Sent

    private let card = PrimerPaymentMethodType.paymentCard.rawValue
    private let funnel = FunnelAnalyticsInteractor()
    private let repository = MockHeadlessRepository()
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
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_savedCardPaidFromTheList_isSelectedAndPaid() async throws {
        repository.paymentResultToReturn = PaymentResult(paymentId: "pay_1", status: .success, paymentMethodType: card)
        sut = try await makeSettledScope()

        try await selectSavedCard().payWithVaultedPaymentMethod()

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, card, attempt: 1),
            Sent(.paymentProcessingStarted, card, attempt: 1),
            Sent(.paymentSubmitted, card, attempt: 1),
            Sent(.paymentSuccess, card, attempt: 1)
        ])
    }

    func test_savedCardThatNeedsItsCvv_isSelectedOnceTheCvvIsSubmitted() async throws {
        repository.paymentResultToReturn = PaymentResult(paymentId: "pay_1", status: .success, paymentMethodType: card)
        sut = try await makeSettledScope()
        try enableCvvRecapture()
        let selection = try selectSavedCard()

        await selection.payWithVaultedPaymentMethod()
        try await funnel.settle()
        let beforeCvv = await funnel.sent
        XCTAssertEqual(beforeCvv, [Sent(.checkoutFlowStarted)])

        await selection.payWithVaultedPaymentMethodAndCvv("123")

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, card, attempt: 1),
            Sent(.paymentProcessingStarted, card, attempt: 1),
            Sent(.paymentSubmitted, card, attempt: 1),
            Sent(.paymentSuccess, card, attempt: 1)
        ])
    }

    func test_retryAfterASavedCardFailure_isASecondAttempt() async throws {
        repository.processVaultedPaymentError = paymentFailed()
        sut = try await makeSettledScope()
        try await selectSavedCard().payWithVaultedPaymentMethod()
        try await funnel.waitFor(.paymentFailure)

        repository.processVaultedPaymentError = nil
        repository.paymentResultToReturn = PaymentResult(paymentId: "pay_2", status: .success, paymentMethodType: card)
        sut.retryPayment()

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, card, attempt: 1),
            Sent(.paymentProcessingStarted, card, attempt: 1),
            Sent(.paymentSubmitted, card, attempt: 1),
            Sent(.paymentFailure, card, attempt: 1),
            Sent(.paymentReattempted, card, attempt: 2),
            Sent(.paymentProcessingStarted, card, attempt: 2),
            Sent(.paymentSubmitted, card, attempt: 2),
            Sent(.paymentSuccess, card, attempt: 2)
        ])
    }

    func test_savedCardPaymentThatTheMerchantAborts_isUnselectedWithoutSubmitting() async throws {
        sut = try await makeSettledScope()
        sut.onBeforePaymentCreate = { _, decide in decide(.abortPaymentCreation(withErrorMessage: nil)) }

        try await selectSavedCard().payWithVaultedPaymentMethod()

        try await funnel.waitFor(.paymentMethodUnselected)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, card, attempt: 1),
            Sent(.paymentMethodUnselected, card, attempt: 1, reason: "merchant_abort")
        ])
    }

    // MARK: - Helpers

    private func paymentFailed() -> PrimerError {
        .paymentFailed(paymentMethodType: card, paymentId: "pay_1", orderId: nil, status: "DECLINED", diagnosticsId: "diag")
    }

    private func selectSavedCard() throws -> any PaymentMethodSelectionScopeInternal {
        let savedCard = try XCTUnwrap(sut.selectedVaultedPaymentMethod)
        let selection = sut.paymentMethodSelectionInternal
        selection.selectVaultedPaymentMethod(savedCard)
        return selection
    }

    private func enableCvvRecapture() throws {
        let container = try XCTUnwrap(DIContainer.currentSync)
        let configuration = try XCTUnwrap(container.resolveSync(ConfigurationService.self) as? MockConfigurationService)
        configuration.captureVaultedCardCvv = true
    }

    private func makeSettledScope() async throws -> DefaultCheckoutScope {
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paymentCardPaymentMethod])
        let instrument = try JSONDecoder().decode(
            Response.Body.Tokenization.PaymentInstrumentData.self,
            from: Data(#"{"last4Digits":"4242"}"#.utf8)
        )
        // A saved card keeps the checkout on the list instead of opening its only method.
        repository.vaultedPaymentMethodsToReturn = [
            PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
                id: "vault_1",
                paymentMethodType: card,
                paymentInstrumentType: .paymentCard,
                paymentInstrumentData: instrument,
                analyticsId: "analytics_vault_1"
            )
        ]
        let container = try await ContainerTestHelpers.createTestContainer(
            apiConfiguration: PrimerAPIConfigurationModule.apiConfiguration,
            analyticsInteractor: funnel
        )
        _ = try await container.register(HeadlessRepository.self)
            .asSingleton()
            .with { [repository] _ in repository }
        _ = try await container.register(SubmitVaultedPaymentInteractor.self)
            .asSingleton()
            .with { [repository] _ in SubmitVaultedPaymentInteractorImpl(repository: repository) }
        await DIContainer.setContainer(container)

        let scope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(uiOptions: PrimerUIOptions(isInitScreenEnabled: false)),
            navigator: CheckoutNavigator(coordinator: CheckoutCoordinator())
        )
        for _ in 0 ..< 200 {
            if case .initializing = scope.currentState {
                try await Task.sleep(nanoseconds: 10_000_000)
                continue
            }
            // A shopper taps only once the list shows, by when the checkout's start was sent.
            try await funnel.waitFor(.checkoutFlowStarted)
            return scope
        }
        throw TestError.timeout
    }
}
