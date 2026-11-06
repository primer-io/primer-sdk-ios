//
//  CardFormFunnelConformanceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
import XCTest

/// The exact events a card form payment sends, after the funnel rules.
@available(iOS 15.0, *)
@MainActor
final class CardFormFunnelConformanceTests: XCTestCase {

    private typealias Sent = FunnelAnalyticsInteractor.Sent

    private let card = PrimerPaymentMethodType.paymentCard.rawValue
    private let funnel = FunnelAnalyticsInteractor()
    private let paymentInteractor = MockProcessCardPaymentInteractor()
    private var sut: DefaultCheckoutScope!
    private var cardForm: DefaultCardFormScope!
    private var integrationType: PrimerSDKIntegrationType?

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
        integrationType = PrimerInternal.shared.sdkIntegrationType
        PrimerInternal.shared.sdkIntegrationType = .checkoutComponents
    }

    override func tearDown() async throws {
        cardForm = nil
        sut = nil
        PrimerInternal.shared.sdkIntegrationType = integrationType
        PrimerAPIConfigurationModule.apiClient = nil
        SDKSessionHelper.tearDown()
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_payingWithTheOnlyCard_sendsSelectionOnFirstInputThenSuccess() async throws {
        paymentInteractor.resultToReturn = PaymentResult(paymentId: "pay_1", status: .success, paymentMethodType: card)
        try await openCardForm()
        try await fillCard()

        await cardForm.performSubmit()

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, card, attempt: 1),
            Sent(.paymentDetailsEntered, card, attempt: 1),
            Sent(.paymentProcessingStarted, card, attempt: 1),
            Sent(.paymentSubmitted, card, attempt: 1),
            Sent(.paymentSuccess, card, attempt: 1)
        ])
    }

    func test_declinedCardThenRetry_sendsFailureThenASecondAttempt() async throws {
        paymentInteractor.errorToThrow = declined()
        paymentInteractor.resultToReturn = PaymentResult(paymentId: "pay_2", status: .success, paymentMethodType: card)
        try await openCardForm()
        try await fillCard()
        await cardForm.performSubmit()
        try await funnel.waitFor(.paymentFailure)

        paymentInteractor.errorToThrow = nil
        sut.retryPayment()

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, card, attempt: 1),
            Sent(.paymentDetailsEntered, card, attempt: 1),
            Sent(.paymentProcessingStarted, card, attempt: 1),
            Sent(.paymentSubmitted, card, attempt: 1),
            Sent(.paymentFailure, card, attempt: 1),
            Sent(.paymentReattempted, card, attempt: 2),
            Sent(.paymentProcessingStarted, card, attempt: 2),
            Sent(.paymentSubmitted, card, attempt: 2),
            Sent(.paymentSuccess, card, attempt: 2)
        ])
    }

    func test_failedBillingAddressUpload_stillCountsAsASubmittedPayment() async throws {
        try await openCardForm()
        try await fillCard()
        enter("94105", in: .postalCode)
        let apiClient = MockPrimerAPIClient()
        apiClient.mockedNetworkDelay = 0
        apiClient.fetchConfigurationWithActionsResult = (nil, NSError(domain: "test", code: 500))
        PrimerAPIConfigurationModule.apiClient = apiClient

        await cardForm.performSubmit()

        try await funnel.waitFor(.paymentFailure)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, card, attempt: 1),
            Sent(.paymentDetailsEntered, card, attempt: 1),
            Sent(.paymentProcessingStarted, card, attempt: 1),
            Sent(.paymentSubmitted, card, attempt: 1),
            Sent(.paymentFailure, card, attempt: 1)
        ])
        XCTAssertEqual(paymentInteractor.executeCallCount, 0)
    }

    func test_merchantAbortBeforeThePayment_sendsUnselectedAndNoSubmit() async throws {
        try await openCardForm()
        sut.onBeforePaymentCreate = { _, decide in decide(.abortPaymentCreation(withErrorMessage: nil)) }
        try await fillCard()

        await cardForm.performSubmit()

        try await funnel.waitFor(.paymentMethodUnselected)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, card, attempt: 1),
            Sent(.paymentDetailsEntered, card, attempt: 1),
            Sent(.paymentMethodUnselected, card, attempt: 1, reason: "merchant_abort")
        ])
        XCTAssertEqual(paymentInteractor.executeCallCount, 0)
    }

    func test_cancellingTheCardFormOpenedFromTheList_sendsUnselectedShopperCancel() async throws {
        try await openCardForm(alongside: [Mocks.PaymentMethods.paypalPaymentMethod])
        sut.paymentMethodSelection.onPaymentMethodSelected(paymentMethod: CheckoutPaymentMethod(id: card, type: card, name: "Card"))
        try await funnel.waitFor(.paymentMethodSelection)
        enter(TestData.CardNumbers.validVisa, in: .cardNumber)
        // The input's duplicate selection sends nothing, so only a settle lets it land before the shopper leaves.
        try await funnel.settle()

        cardForm.cancel()

        try await funnel.waitFor(.paymentMethodUnselected)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, card, attempt: 1),
            Sent(.paymentMethodUnselected, card, attempt: 1, reason: "shopper_cancel")
        ])
        XCTAssertEqual(sut.currentNavigationState, .paymentMethodSelection)
    }

    // MARK: - Helpers

    private func declined() -> PrimerError {
        .paymentFailed(paymentMethodType: card, paymentId: "pay_1", orderId: nil, status: "DECLINED", diagnosticsId: "diag")
    }

    /// Only the card means the checkout opens the form itself, so the form's first input selects it.
    private func openCardForm(alongside otherMethods: [PrimerPaymentMethod] = []) async throws {
        sut = try await makeSettledScope(paymentMethods: [Mocks.PaymentMethods.paymentCardPaymentMethod] + otherMethods)
        cardForm = try XCTUnwrap(sut.getPaymentMethodScope(DefaultCardFormScope.self))
        try await funnel.waitFor(.checkoutFlowStarted)
    }

    /// What a card field does on each edit.
    private func enter(_ value: String, in field: PrimerInputElementType) {
        cardForm.updateField(field, value: value)
        cardForm.updateValidationStateIfNeeded(for: field, isValid: true)
    }

    // Each step's event is sent from its own task, so a step waits for it before the next input.
    private func fillCard() async throws {
        enter(TestData.CardNumbers.validVisa, in: .cardNumber)
        try await funnel.waitFor(.paymentMethodSelection)
        enter("123", in: .cvv)
        enter("12/30", in: .expiryDate)
        enter("John Doe", in: .cardholderName)
        try await funnel.waitFor(.paymentDetailsEntered)
    }

    private func makeSettledScope(paymentMethods: [PrimerPaymentMethod]) async throws -> DefaultCheckoutScope {
        SDKSessionHelper.setUp(withPaymentMethods: paymentMethods)
        let container = try await ContainerTestHelpers.createTestContainer(
            apiConfiguration: PrimerAPIConfigurationModule.apiConfiguration,
            analyticsInteractor: funnel
        )
        _ = try await container.register(ProcessCardPaymentInteractor.self)
            .asSingleton()
            .with { [paymentInteractor] _ in paymentInteractor }
        await DIContainer.setContainer(container)

        let scope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(uiOptions: PrimerUIOptions(isInitScreenEnabled: false)),
            navigator: CheckoutNavigator(coordinator: CheckoutCoordinator())
        )
        for _ in 0 ..< 200 {
            if case .initializing = scope.currentState {} else { return scope }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        throw TestError.timeout
    }
}
