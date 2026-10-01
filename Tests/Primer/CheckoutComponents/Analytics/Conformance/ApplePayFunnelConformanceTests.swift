//
//  ApplePayFunnelConformanceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit
@_spi(PrimerInternal) @testable import PrimerNetworking
@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
import XCTest

/// The exact events a real checkout sends, after the funnel rules, when the shopper pays with Apple Pay.
@available(iOS 15.0, *)
@MainActor
final class ApplePayFunnelConformanceTests: XCTestCase {

    private typealias Sent = FunnelAnalyticsInteractor.Sent

    private let applePay = PrimerPaymentMethodType.applePay.rawValue
    private let funnel = FunnelAnalyticsInteractor()
    private let presenter = MockApplePayPresentationManager()
    private let clientSessionActions = MockClientSessionActionsModule()
    private let tokenization = MockTokenizationService()
    private let payments = MockCreateResumePaymentService()
    private var sut: DefaultCheckoutScope!
    private var applePayScope: DefaultApplePayScope!
    private var integrationType: PrimerSDKIntegrationType?

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
        integrationType = PrimerInternal.shared.sdkIntegrationType
        PrimerInternal.shared.sdkIntegrationType = .checkoutComponents
        tokenization.onTokenize = { _ in .success(ApplePayTestData.tokenizationResponse) }
        payments.onCreatePayment = { _ in ApplePayTestData.paymentResponse() }
    }

    override func tearDown() async throws {
        applePayScope?.paymentTask?.cancel()
        await applePayScope?.paymentTask?.value
        applePayScope = nil
        sut = nil
        // The shared registry outlives the test, so it gets the production creator back.
        ApplePayPaymentMethod.register()
        PrimerInternal.shared.sdkIntegrationType = integrationType
        SDKSessionHelper.tearDown()
        // The settings are global, and later Apple Pay tests expect no Apple Pay options.
        DependencyContainer.register(PrimerSettings() as PrimerSettingsProtocol)
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_onlyApplePayOpenedByTheCheckout_isSelectedAndPaid() async throws {
        try await makeSettledScope(paymentMethods: [ApplePayTestData.applePayPaymentMethod])
        try await funnel.waitFor(.paymentMethodSelection)
        sut.onBeforePaymentCreate = { _, decide in decide(.continuePaymentCreation()) }
        shopperAnswersTheSheet(authorizing: true)

        applePayScope.submit()

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, applePay, attempt: 1),
            Sent(.paymentProcessingStarted, applePay, attempt: 1),
            Sent(.paymentSubmitted, applePay, attempt: 1),
            Sent(.paymentSuccess, applePay, attempt: 1)
        ])
    }

    // A second method keeps the checkout open, so closing the sheet returns to the list.
    func test_closingTheApplePaySheet_unselectsWithoutAFailure() async throws {
        try await makeSettledScope(paymentMethods: [
            ApplePayTestData.applePayPaymentMethod,
            Mocks.PaymentMethods.paymentCardPaymentMethod
        ])
        try await funnel.waitFor(.checkoutFlowStarted)
        shopperAnswersTheSheet(authorizing: false)

        sut.paymentMethodSelection.onPaymentMethodSelected(
            paymentMethod: CheckoutPaymentMethod(id: applePay, type: applePay, name: "Apple Pay")
        )
        applePayScope.submit()

        try await funnel.waitFor(.paymentMethodUnselected)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, applePay, attempt: 1),
            Sent(.paymentMethodUnselected, applePay, attempt: 1, reason: "shopper_cancel")
        ])
    }

    func test_declinedApplePayPayment_sendsFailure() async throws {
        payments.onCreatePayment = { _ in ApplePayTestData.paymentResponse(status: .failed) }
        try await makeSettledScope(paymentMethods: [ApplePayTestData.applePayPaymentMethod])
        try await funnel.waitFor(.paymentMethodSelection)
        shopperAnswersTheSheet(authorizing: true)

        applePayScope.submit()

        try await funnel.waitFor(.paymentFailure)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, applePay, attempt: 1),
            Sent(.paymentProcessingStarted, applePay, attempt: 1),
            Sent(.paymentSubmitted, applePay, attempt: 1),
            Sent(.paymentFailure, applePay, attempt: 1)
        ])
    }

    func test_retryAfterADecline_opensASecondAttempt() async throws {
        payments.onCreatePayment = { _ in ApplePayTestData.paymentResponse(status: .failed) }
        try await makeSettledScope(paymentMethods: [ApplePayTestData.applePayPaymentMethod])
        try await funnel.waitFor(.paymentMethodSelection)
        shopperAnswersTheSheet(authorizing: true)
        applePayScope.submit()
        try await funnel.waitFor(.paymentFailure)
        await applePayScope.paymentTask?.value

        payments.onCreatePayment = { _ in ApplePayTestData.paymentResponse() }
        sut.retryPayment()
        try await funnel.waitFor(.paymentReattempted)
        // The retry reopens Apple Pay, and the shopper taps its button again.
        applePayScope.submit()

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, applePay, attempt: 1),
            Sent(.paymentProcessingStarted, applePay, attempt: 1),
            Sent(.paymentSubmitted, applePay, attempt: 1),
            Sent(.paymentFailure, applePay, attempt: 1),
            Sent(.paymentReattempted, applePay, attempt: 2),
            Sent(.paymentProcessingStarted, applePay, attempt: 2),
            Sent(.paymentSubmitted, applePay, attempt: 2),
            Sent(.paymentSuccess, applePay, attempt: 2)
        ])
    }

    // MARK: - Helpers

    /// The sheet answers on the main actor after it is presented, as PassKit does.
    private func shopperAnswersTheSheet(authorizing: Bool) {
        presenter.onPresent = { _, delegate in
            Task { @MainActor in
                let sheet = ImmediatelyDismissedSheet()
                if authorizing {
                    delegate.paymentAuthorizationController?(sheet, didAuthorizePayment: SharedMockPKPayment(), handler: { _ in })
                } else {
                    delegate.paymentAuthorizationControllerDidFinish(sheet)
                }
            }
            return .success(())
        }
    }

    private func makeSettledScope(paymentMethods: [PrimerPaymentMethod]) async throws {
        SDKSessionHelper.setUp(withPaymentMethods: paymentMethods)
        ApplePayTestData.registerApplePaySettings()
        let container = try await ContainerTestHelpers.createTestContainer(
            apiConfiguration: PrimerAPIConfigurationModule.apiConfiguration,
            analyticsInteractor: funnel
        )
        let interactor = ProcessApplePayPaymentInteractorImpl(tokenizationService: tokenization, createPaymentService: payments)
        _ = try await container.register(ProcessApplePayPaymentInteractor.self)
            .asSingleton()
            .with { _ in interactor }
        await DIContainer.setContainer(container)

        sut = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(uiOptions: PrimerUIOptions(isInitScreenEnabled: false)),
            navigator: CheckoutNavigator(coordinator: CheckoutCoordinator())
        )
        // Replaces the registration the scope's init just made, before its load task preloads the method scopes.
        PaymentMethodRegistry.shared.register(
            forKey: applePay,
            scopeCreator: { [presenter, clientSessionActions] checkoutScope, _ in
                let (scope, context) = try DefaultCheckoutScope.validated(from: checkoutScope)
                return DefaultApplePayScope(
                    checkoutScope: scope,
                    presentationContext: context,
                    applePayPresentationManager: presenter,
                    clientSessionActionsFactory: { clientSessionActions },
                    applePayRequestFactory: {
                        ApplePayRequest(
                            currency: Currency(code: "GBP", decimalDigits: 2),
                            merchantIdentifier: ApplePayTestData.Constants.merchantIdentifier,
                            countryCode: .gb,
                            items: []
                        )
                    }
                )
            },
            viewCreator: { _ in nil }
        )
        for _ in 0 ..< 200 {
            if case .initializing = sut.currentState {} else {
                applePayScope = try XCTUnwrap(sut.getPaymentMethodScope(DefaultApplePayScope.self))
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        throw TestError.timeout
    }
}

/// Calls back at once, because the coordinator resumes only inside the dismiss completion.
@available(iOS 15.0, *)
private final class ImmediatelyDismissedSheet: PKPaymentAuthorizationController {

    override func dismiss(completion: (() -> Void)? = nil) {
        completion?()
    }
}
