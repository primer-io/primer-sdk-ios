//
//  WebRedirectFunnelConformanceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
import XCTest

/// The exact events a web redirect payment picked from the list sends, after the funnel rules.
@available(iOS 15.0, *)
@MainActor
final class WebRedirectFunnelConformanceTests: XCTestCase {

    private typealias Sent = FunnelAnalyticsInteractor.Sent

    private let ideal = Mocks.PaymentMethods.adyenIDealPaymentMethod
    private let giropay = Mocks.PaymentMethods.adyenGiroPayRedirectPaymentMethod
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
        repository.resumePaymentResult = .success(paid())
    }

    override func tearDown() async throws {
        sut = nil
        PrimerInternal.shared.sdkIntegrationType = integrationType
        SDKSessionHelper.tearDown()
        DependencyContainer.register(PrimerSettings() as PrimerSettingsProtocol)
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_methodPickedFromTheList_isRedirectedAndPaid() async throws {
        sut = try await makeReadyScope()

        pick(ideal)

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
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

    func test_shopperClosingTheWebPage_unselectsTheMethod() async throws {
        repository.openWebAuthResult = .failure(PrimerError.cancelled(paymentMethodType: ideal.type))
        sut = try await makeReadyScope()

        pick(ideal)

        try await funnel.waitFor(.paymentMethodUnselected)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, ideal.type, attempt: 1),
            Sent(.paymentProcessingStarted, ideal.type, attempt: 1),
            Sent(.paymentRedirectToThirdParty, ideal.type, attempt: 1),
            Sent(.paymentMethodUnselected, ideal.type, attempt: 1, reason: "shopper_cancel")
        ])
    }

    func test_pickingTheMethodAgainAfterClosingThePage_opensAnAttemptWithoutASecondSelection() async throws {
        repository.openWebAuthResult = .failure(PrimerError.cancelled(paymentMethodType: ideal.type))
        sut = try await makeReadyScope()
        pick(ideal)
        try await funnel.waitFor(.paymentMethodUnselected)

        repository.openWebAuthResult = .success(URL(string: "https://callback.example.com")!)
        pick(ideal)

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, ideal.type, attempt: 1),
            Sent(.paymentProcessingStarted, ideal.type, attempt: 1),
            Sent(.paymentRedirectToThirdParty, ideal.type, attempt: 1),
            Sent(.paymentMethodUnselected, ideal.type, attempt: 1, reason: "shopper_cancel"),
            Sent(.paymentProcessingStarted, ideal.type, attempt: 2),
            Sent(.paymentRedirectToThirdParty, ideal.type, attempt: 2),
            Sent(.paymentReturnedFromThirdParty, ideal.type, attempt: 2),
            Sent(.paymentSubmitted, ideal.type, attempt: 2),
            Sent(.paymentSuccess, ideal.type, attempt: 2)
        ])
    }

    func test_declineRetriedByTheSDK_isASecondAttempt() async throws {
        repository.resumePaymentResult = .failure(PrimerError.paymentFailed(
            paymentMethodType: ideal.type,
            paymentId: "mock_payment_id",
            orderId: nil,
            status: "DECLINED",
            diagnosticsId: "diag"
        ))
        sut = try await makeReadyScope()
        pick(ideal)
        try await funnel.waitFor(.paymentFailure)

        repository.resumePaymentResult = .success(paid())
        sut.retryPayment()

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, ideal.type, attempt: 1),
            Sent(.paymentProcessingStarted, ideal.type, attempt: 1),
            Sent(.paymentRedirectToThirdParty, ideal.type, attempt: 1),
            Sent(.paymentReturnedFromThirdParty, ideal.type, attempt: 1),
            Sent(.paymentSubmitted, ideal.type, attempt: 1),
            Sent(.paymentFailure, ideal.type, attempt: 1),
            Sent(.paymentReattempted, ideal.type, attempt: 2),
            Sent(.paymentProcessingStarted, ideal.type, attempt: 2),
            Sent(.paymentRedirectToThirdParty, ideal.type, attempt: 2),
            Sent(.paymentReturnedFromThirdParty, ideal.type, attempt: 2),
            Sent(.paymentSubmitted, ideal.type, attempt: 2),
            Sent(.paymentSuccess, ideal.type, attempt: 2)
        ])
    }

    // MARK: - Helpers

    private func paid() -> PaymentResult {
        PaymentResult(paymentId: "mock_payment_id", status: .success, paymentMethodType: ideal.type)
    }

    private func pick(_ method: PrimerPaymentMethod) {
        sut.paymentMethodSelection.onPaymentMethodSelected(
            paymentMethod: CheckoutPaymentMethod(id: method.type, type: method.type, name: method.name)
        )
    }

    private func makeReadyScope() async throws -> DefaultCheckoutScope {
        // A second method keeps the checkout on the list instead of opening the only one.
        SDKSessionHelper.setUp(withPaymentMethods: [ideal, giropay])
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
            if case .ready = scope.currentState {
                // FLOW_STARTED goes out on its own task, so a pick before it lands could race it.
                try await funnel.waitFor(.checkoutFlowStarted)
                return scope
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        throw TestError.timeout
    }
}
