//
//  BillingAddressFunnelConformanceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
import XCTest

/// The exact events a billing-address redirect method (Affirm) sends through a real checkout, after the funnel rules.
@available(iOS 15.0, *)
@MainActor
final class BillingAddressFunnelConformanceTests: XCTestCase {

    private typealias Sent = FunnelAnalyticsInteractor.Sent

    private let affirm = PrimerPaymentMethodType.adyenAffirm.rawValue
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
        PrimerAPIConfigurationModule.apiClient = nil
        SDKSessionHelper.tearDown()
        DependencyContainer.register(PrimerSettings() as PrimerSettingsProtocol)
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_payWithAffirm_sendsTheRedirectLegThenSuccess() async throws {
        repository.resumePaymentResult = .success(paid())
        sut = try await makeSettledScope()

        try await payWithAffirm()

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, affirm, attempt: 1),
            Sent(.paymentProcessingStarted, affirm, attempt: 1),
            Sent(.paymentRedirectToThirdParty, affirm, attempt: 1),
            Sent(.paymentReturnedFromThirdParty, affirm, attempt: 1),
            Sent(.paymentSubmitted, affirm, attempt: 1),
            Sent(.paymentSuccess, affirm, attempt: 1)
        ])
    }

    func test_closingTheAffirmPage_unselectsWithoutAFailure() async throws {
        repository.openWebAuthResult = .failure(PrimerError.cancelled(paymentMethodType: affirm))
        sut = try await makeSettledScope()

        try await payWithAffirm()

        try await funnel.waitFor(.paymentMethodUnselected)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, affirm, attempt: 1),
            Sent(.paymentProcessingStarted, affirm, attempt: 1),
            Sent(.paymentRedirectToThirdParty, affirm, attempt: 1),
            Sent(.paymentMethodUnselected, affirm, attempt: 1, reason: "shopper_cancel")
        ])
    }

    func test_declinedPayment_sendsFailure() async throws {
        repository.resumePaymentResult = .failure(declined())
        sut = try await makeSettledScope()

        try await payWithAffirm()

        try await funnel.waitFor(.paymentFailure)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, affirm, attempt: 1),
            Sent(.paymentProcessingStarted, affirm, attempt: 1),
            Sent(.paymentRedirectToThirdParty, affirm, attempt: 1),
            Sent(.paymentReturnedFromThirdParty, affirm, attempt: 1),
            Sent(.paymentSubmitted, affirm, attempt: 1),
            Sent(.paymentFailure, affirm, attempt: 1)
        ])
    }

    func test_retryAfterADecline_isASecondAttempt() async throws {
        repository.resumePaymentResult = .failure(declined())
        sut = try await makeSettledScope()
        try await payWithAffirm()
        try await funnel.waitFor(.paymentFailure)
        try await funnel.settle()

        repository.resumePaymentResult = .success(paid())
        sut.retryPayment()

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, affirm, attempt: 1),
            Sent(.paymentProcessingStarted, affirm, attempt: 1),
            Sent(.paymentRedirectToThirdParty, affirm, attempt: 1),
            Sent(.paymentReturnedFromThirdParty, affirm, attempt: 1),
            Sent(.paymentSubmitted, affirm, attempt: 1),
            Sent(.paymentFailure, affirm, attempt: 1),
            Sent(.paymentReattempted, affirm, attempt: 2),
            Sent(.paymentProcessingStarted, affirm, attempt: 2),
            Sent(.paymentRedirectToThirdParty, affirm, attempt: 2),
            Sent(.paymentReturnedFromThirdParty, affirm, attempt: 2),
            Sent(.paymentSubmitted, affirm, attempt: 2),
            Sent(.paymentSuccess, affirm, attempt: 2)
        ])
    }

    // MARK: - Helpers

    private func paid() -> PaymentResult {
        PaymentResult(paymentId: "pay_1", status: .success, paymentMethodType: affirm)
    }

    private func declined() -> PrimerError {
        .paymentFailed(paymentMethodType: affirm, paymentId: "pay_1", orderId: nil, status: "DECLINED", diagnosticsId: "diag")
    }

    /// Picks Affirm from the list, fills the billing address and pays, as the shopper does.
    private func payWithAffirm() async throws {
        sut.paymentMethodSelection.onPaymentMethodSelected(
            paymentMethod: CheckoutPaymentMethod(id: affirm, type: affirm, name: "Affirm")
        )
        try await funnel.waitFor(.paymentMethodSelection)

        // The billing address goes to the client session before the redirect.
        let apiClient = MockPrimerAPIClient()
        apiClient.mockedNetworkDelay = 0
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)
        PrimerAPIConfigurationModule.apiClient = apiClient

        let cached: DefaultBillingAddressRedirectScope? = sut.getPaymentMethodScope(for: affirm)
        let scope = try XCTUnwrap(cached)
        scope.updateCountryCode("US")
        scope.updateAddressLine1("123 Main St")
        scope.updatePostalCode("94105")
        scope.updateCity("San Francisco")
        scope.updateState("CA")
        scope.submit()
    }

    private func makeSettledScope() async throws -> DefaultCheckoutScope {
        let affirmMethod = PrimerPaymentMethod(
            id: "affirm_id",
            implementationType: .nativeSdk,
            type: affirm,
            name: "Affirm",
            processorConfigId: nil,
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        // A second method gives Affirm a list to go back to, so a cancel keeps the checkout open.
        SDKSessionHelper.setUp(withPaymentMethods: [affirmMethod, Mocks.PaymentMethods.paymentCardPaymentMethod])
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
            navigator: CheckoutNavigator(coordinator: CheckoutCoordinator())
        )
        for _ in 0 ..< 200 {
            if case .initializing = scope.currentState {} else { return scope }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        throw TestError.timeout
    }
}
