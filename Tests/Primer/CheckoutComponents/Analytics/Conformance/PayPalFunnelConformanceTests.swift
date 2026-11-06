//
//  PayPalFunnelConformanceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
import XCTest

/// The exact events a PayPal payment sends through a real checkout, after the funnel rules.
@available(iOS 15.0, *)
@MainActor
final class PayPalFunnelConformanceTests: XCTestCase {

    private typealias Sent = FunnelAnalyticsInteractor.Sent

    private let payPal = Mocks.PaymentMethods.paypalPaymentMethod
    private let funnel = FunnelAnalyticsInteractor()
    private let repository = PayPalRepositoryStub()
    private var sut: DefaultCheckoutScope!
    private var integrationType: PrimerSDKIntegrationType?
    private var intent: PrimerSessionIntent?

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
        integrationType = PrimerInternal.shared.sdkIntegrationType
        PrimerInternal.shared.sdkIntegrationType = .checkoutComponents
        // Other tests leave a vault intent behind, which runs the billing-agreement flow instead.
        intent = PrimerInternal.shared.intent
        PrimerInternal.shared.intent = .checkout
    }

    override func tearDown() async throws {
        sut = nil
        PrimerInternal.shared.sdkIntegrationType = integrationType
        PrimerInternal.shared.intent = intent
        SDKSessionHelper.tearDown()
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_payPalPayment_sendsTheRedirectFunnelThenSuccess() async throws {
        sut = try await makeSettledScope(paymentMethods: [payPal])

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, payPal.type, attempt: 1),
            Sent(.paymentProcessingStarted, payPal.type, attempt: 1),
            Sent(.paymentRedirectToThirdParty, payPal.type, attempt: 1),
            Sent(.paymentReturnedFromThirdParty, payPal.type, attempt: 1),
            Sent(.paymentSubmitted, payPal.type, attempt: 1),
            Sent(.paymentSuccess, payPal.type, attempt: 1)
        ])
        let redirect = await funnel.outputs.first { $0.eventType == .paymentRedirectToThirdParty }
        XCTAssertEqual(redirect?.metadata?.redirectDestinationUrl, "https://www.paypal.com")
    }

    func test_closingThePayPalPage_sendsUnselectedShopperCancel() async throws {
        repository.openWebAuthenticationResult = .failure(PrimerError.cancelled(paymentMethodType: payPal.type))
        // A second method sends the shopper back to the list, so the cancel does not also exit the checkout.
        sut = try await makeSettledScope(paymentMethods: [payPal, Mocks.PaymentMethods.paymentCardPaymentMethod])
        let method = try XCTUnwrap(sut.availablePaymentMethods.first { $0.type == payPal.type })
        sut.handlePaymentMethodSelection(method)

        try await funnel.waitFor(.paymentMethodUnselected)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, payPal.type, attempt: 1),
            Sent(.paymentProcessingStarted, payPal.type, attempt: 1),
            Sent(.paymentRedirectToThirdParty, payPal.type, attempt: 1),
            Sent(.paymentMethodUnselected, payPal.type, attempt: 1, reason: "shopper_cancel")
        ])
    }

    func test_declinedPayPalPayment_sendsFailure() async throws {
        repository.createPaymentResult = .failure(declined())
        sut = try await makeSettledScope(paymentMethods: [payPal])

        try await funnel.waitFor(.paymentFailure)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, payPal.type, attempt: 1),
            Sent(.paymentProcessingStarted, payPal.type, attempt: 1),
            Sent(.paymentRedirectToThirdParty, payPal.type, attempt: 1),
            Sent(.paymentReturnedFromThirdParty, payPal.type, attempt: 1),
            Sent(.paymentSubmitted, payPal.type, attempt: 1),
            Sent(.paymentFailure, payPal.type, attempt: 1)
        ])
    }

    func test_retryAfterADecline_opensASecondAttempt() async throws {
        repository.createPaymentResult = .failure(declined())
        sut = try await makeSettledScope(paymentMethods: [payPal])
        try await funnel.waitFor(.paymentFailure)

        repository.createPaymentResult = .success(PayPalRepositoryStub.paid)
        sut.retryPayment()

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, payPal.type, attempt: 1),
            Sent(.paymentProcessingStarted, payPal.type, attempt: 1),
            Sent(.paymentRedirectToThirdParty, payPal.type, attempt: 1),
            Sent(.paymentReturnedFromThirdParty, payPal.type, attempt: 1),
            Sent(.paymentSubmitted, payPal.type, attempt: 1),
            Sent(.paymentFailure, payPal.type, attempt: 1),
            Sent(.paymentReattempted, payPal.type, attempt: 2),
            Sent(.paymentProcessingStarted, payPal.type, attempt: 2),
            Sent(.paymentRedirectToThirdParty, payPal.type, attempt: 2),
            Sent(.paymentReturnedFromThirdParty, payPal.type, attempt: 2),
            Sent(.paymentSubmitted, payPal.type, attempt: 2),
            Sent(.paymentSuccess, payPal.type, attempt: 2)
        ])
    }

    // MARK: - Helpers

    private func declined() -> PrimerError {
        .paymentFailed(paymentMethodType: payPal.type, paymentId: "pay_1", orderId: nil, status: "DECLINED")
    }

    private func makeSettledScope(paymentMethods: [PrimerPaymentMethod]) async throws -> DefaultCheckoutScope {
        SDKSessionHelper.setUp(withPaymentMethods: paymentMethods)
        let container = try await ContainerTestHelpers.createTestContainer(
            apiConfiguration: PrimerAPIConfigurationModule.apiConfiguration,
            analyticsInteractor: funnel
        )
        let interactor = ProcessPayPalPaymentInteractorImpl(repository: repository, analytics: funnel)
        _ = try await container.register(ProcessPayPalPaymentInteractor.self)
            .asSingleton()
            .with { _ in interactor }
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

@available(iOS 15.0, *)
private final class PayPalRepositoryStub: PayPalRepository {

    static let paid = PaymentResult(paymentId: "pay_1", status: .success, paymentMethodType: PrimerPaymentMethodType.payPal.rawValue)

    var openWebAuthenticationResult: Result<URL, Error> = .success(URL(string: "testapp://paypal-success")!)
    var createPaymentResult: Result<PaymentResult, Error> = .success(PayPalRepositoryStub.paid)

    func startOrderSession() async throws -> (orderId: String, approvalUrl: String) {
        ("order_1", "https://www.paypal.com/checkoutnow?token=order_1")
    }

    func startBillingAgreementSession() async throws -> String {
        "https://www.paypal.com/agreements/approve?ba_token=ba_1"
    }

    func openWebAuthentication(url: URL) async throws -> URL {
        try openWebAuthenticationResult.get()
    }

    func confirmBillingAgreement() async throws -> PayPalBillingAgreementResult {
        PayPalBillingAgreementResult(billingAgreementId: "ba_1", externalPayerInfo: nil, shippingAddress: nil)
    }

    func fetchPayerInfo(orderId: String) async throws -> PayPalPayerInfo {
        PayPalPayerInfo(externalPayerId: "payer_1", email: nil, firstName: nil, lastName: nil)
    }

    func tokenize(paymentInstrument: PayPalPaymentInstrumentData) async throws -> PaymentResult {
        PaymentResult(paymentId: "token_1", status: .success, token: "token_1")
    }

    func createPayment(token: String) async throws -> PaymentResult {
        try createPaymentResult.get()
    }
}
