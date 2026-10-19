//
//  AdyenKlarnaFunnelConformanceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
import XCTest

/// The exact events an Adyen Klarna payment sends through a real checkout, after the funnel rules.
@available(iOS 15.0, *)
@MainActor
final class AdyenKlarnaFunnelConformanceTests: XCTestCase {

    private typealias Sent = FunnelAnalyticsInteractor.Sent

    private let klarna = PrimerPaymentMethodType.adyenKlarna.rawValue
    private let klarnaMethod = PrimerPaymentMethod(
        id: "mock_adyen_klarna_payment_method_id",
        implementationType: .nativeSdk,
        type: PrimerPaymentMethodType.adyenKlarna.rawValue,
        name: "Klarna",
        processorConfigId: Mocks.Static.Strings.processorConfigId,
        surcharge: nil,
        options: nil,
        displayMetadata: nil
    )
    private let funnel = FunnelAnalyticsInteractor()
    private let repository = MockAdyenKlarnaRepository()
    private var sut: DefaultCheckoutScope!
    private var integrationType: PrimerSDKIntegrationType?

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
        // The shared core asks the merchant before it creates a payment, and only CheckoutComponents answers itself.
        integrationType = PrimerInternal.shared.sdkIntegrationType
        PrimerInternal.shared.sdkIntegrationType = .checkoutComponents
        // A single option makes the method pay as soon as it opens.
        repository.fetchPaymentOptionsResult = .success([AdyenKlarnaPaymentOption(id: "pay_later", name: "Pay Later")])
    }

    override func tearDown() async throws {
        sut = nil
        PrimerInternal.shared.sdkIntegrationType = integrationType
        SDKSessionHelper.tearDown()
        DependencyContainer.register(PrimerSettings() as PrimerSettingsProtocol)
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_onlyMethodPaidThroughTheRedirect_endsInSuccess() async throws {
        sut = try await makeSettledScope(paymentMethods: [klarnaMethod])

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, klarna, attempt: 1),
            Sent(.paymentProcessingStarted, klarna, attempt: 1),
            Sent(.paymentRedirectToThirdParty, klarna, attempt: 1),
            Sent(.paymentReturnedFromThirdParty, klarna, attempt: 1),
            Sent(.paymentSubmitted, klarna, attempt: 1),
            Sent(.paymentSuccess, klarna, attempt: 1)
        ])
        let redirect = await funnel.outputs.first { $0.eventType == .paymentRedirectToThirdParty }
        XCTAssertEqual(redirect?.metadata?.paymentId, "pay-123")
    }

    // A second method gives the shopper a list to go back to, so closing Klarna keeps the checkout open.
    func test_closingTheKlarnaPage_isAShopperCancelAndNoFailure() async throws {
        repository.openWebAuthResult = .failure(PrimerError.cancelled(paymentMethodType: klarna))
        sut = try await makeSettledScope(paymentMethods: [klarnaMethod, Mocks.PaymentMethods.paymentCardPaymentMethod])
        try await funnel.waitFor(.checkoutFlowStarted)

        sut.paymentMethodSelection.onPaymentMethodSelected(paymentMethod: CheckoutPaymentMethod(id: klarna, type: klarna, name: "Klarna"))

        try await funnel.waitFor(.paymentMethodUnselected)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, klarna, attempt: 1),
            Sent(.paymentProcessingStarted, klarna, attempt: 1),
            Sent(.paymentRedirectToThirdParty, klarna, attempt: 1),
            Sent(.paymentMethodUnselected, klarna, attempt: 1, reason: "shopper_cancel")
        ])
    }

    func test_declinedPayment_endsInFailure() async throws {
        repository.resumePaymentResult = .failure(declined())
        sut = try await makeSettledScope(paymentMethods: [klarnaMethod])

        try await funnel.waitFor(.paymentFailure)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, klarna, attempt: 1),
            Sent(.paymentProcessingStarted, klarna, attempt: 1),
            Sent(.paymentRedirectToThirdParty, klarna, attempt: 1),
            Sent(.paymentReturnedFromThirdParty, klarna, attempt: 1),
            Sent(.paymentSubmitted, klarna, attempt: 1),
            Sent(.paymentFailure, klarna, attempt: 1)
        ])
    }

    func test_retryAfterADecline_paysInASecondAttempt() async throws {
        repository.resumePaymentResult = .failure(declined())
        sut = try await makeSettledScope(paymentMethods: [klarnaMethod])
        try await funnel.waitFor(.paymentFailure)

        repository.resumePaymentResult = .success(PaymentResult(paymentId: "pay-123", status: .success, paymentMethodType: klarna))
        sut.retryPayment()

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, klarna, attempt: 1),
            Sent(.paymentProcessingStarted, klarna, attempt: 1),
            Sent(.paymentRedirectToThirdParty, klarna, attempt: 1),
            Sent(.paymentReturnedFromThirdParty, klarna, attempt: 1),
            Sent(.paymentSubmitted, klarna, attempt: 1),
            Sent(.paymentFailure, klarna, attempt: 1),
            Sent(.paymentReattempted, klarna, attempt: 2),
            Sent(.paymentProcessingStarted, klarna, attempt: 2),
            Sent(.paymentRedirectToThirdParty, klarna, attempt: 2),
            Sent(.paymentReturnedFromThirdParty, klarna, attempt: 2),
            Sent(.paymentSubmitted, klarna, attempt: 2),
            Sent(.paymentSuccess, klarna, attempt: 2)
        ])
    }

    // MARK: - Helpers

    private func declined() -> PrimerError {
        .paymentFailed(paymentMethodType: klarna, paymentId: "pay-123", orderId: nil, status: "DECLINED", diagnosticsId: "diag")
    }

    private func makeSettledScope(paymentMethods: [PrimerPaymentMethod]) async throws -> DefaultCheckoutScope {
        SDKSessionHelper.setUp(withPaymentMethods: paymentMethods)
        // The interactor reads the locale from `PrimerSettings.current`, which needs a real settings object.
        DependencyContainer.register(PrimerSettings() as PrimerSettingsProtocol)
        let container = try await ContainerTestHelpers.createTestContainer(
            apiConfiguration: PrimerAPIConfigurationModule.apiConfiguration,
            analyticsInteractor: funnel
        )
        let interactor = ProcessAdyenKlarnaPaymentInteractorImpl(
            repository: repository,
            clientSessionActionsFactory: { MockClientSessionActionsModule() },
            analytics: funnel
        )
        _ = try await container.register(ProcessAdyenKlarnaPaymentInteractor.self)
            .asSingleton()
            .with { _ in interactor }
        _ = try await container.register(AdyenKlarnaRepository.self)
            .asSingleton()
            .with { [repository] _ in repository }
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
