//
//  FormRedirectFunnelConformanceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
import XCTest

/// The exact events a BLIK payment sends after the funnel rules: a code typed in the form, then approved in the bank app.
@available(iOS 15.0, *)
@MainActor
final class FormRedirectFunnelConformanceTests: XCTestCase {

    private typealias Sent = FunnelAnalyticsInteractor.Sent

    private let blik = PrimerPaymentMethodType.adyenBlik.rawValue
    private let funnel = FunnelAnalyticsInteractor()
    private let repository = MockFormRedirectRepository()
    private var sut: DefaultCheckoutScope!
    private var integrationType: PrimerSDKIntegrationType?

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
        integrationType = PrimerInternal.shared.sdkIntegrationType
        PrimerInternal.shared.sdkIntegrationType = .checkoutComponents
        // BLIK stays pending until the shopper approves it in the bank app, so every payment polls.
        repository.createPaymentResult = .success(FormRedirectTestData.pendingPaymentResponse)
    }

    override func tearDown() async throws {
        sut = nil
        PrimerInternal.shared.sdkIntegrationType = integrationType
        SDKSessionHelper.tearDown()
        DependencyContainer.register(PrimerSettings() as PrimerSettingsProtocol)
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_codeApprovedInTheBankApp_sendsSuccess() async throws {
        sut = try await makeSettledScope()

        try await selectBlikAndEnterCode().submit()

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, blik, attempt: 1),
            Sent(.paymentDetailsEntered, blik, attempt: 1),
            Sent(.paymentProcessingStarted, blik, attempt: 1),
            Sent(.paymentSubmitted, blik, attempt: 1),
            Sent(.paymentSuccess, blik, attempt: 1)
        ])
        XCTAssertEqual(repository.pollForCompletionCallCount, 1)
    }

    func test_shopperCancellingWhileTheBankAppIsPending_sendsUnselected() async throws {
        let interactor = MockProcessFormRedirectPaymentInteractor()
        interactor.shouldHold = true
        sut = try await makeSettledScope(interactor: interactor)
        let form = try await selectBlikAndEnterCode()
        form.submit()
        try await withTimeout(2) { while interactor.executeCallCount == 0 { await Task.yield() } }

        form.cancel()
        try await funnel.waitFor(.paymentMethodUnselected)
        // Cancelling stops the polling, which ends the payment with this error.
        interactor.executeResult = .failure(PrimerError.cancelled(paymentMethodType: blik))
        interactor.release()

        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, blik, attempt: 1),
            Sent(.paymentDetailsEntered, blik, attempt: 1),
            Sent(.paymentProcessingStarted, blik, attempt: 1),
            Sent(.paymentSubmitted, blik, attempt: 1),
            Sent(.paymentMethodUnselected, blik, attempt: 1, reason: "shopper_cancel")
        ])
    }

    func test_codeDeclinedInTheBankApp_sendsFailure() async throws {
        repository.resumePaymentResult = .success(FormRedirectTestData.failedPaymentResponse)
        sut = try await makeSettledScope()

        try await selectBlikAndEnterCode().submit()

        try await funnel.waitFor(.paymentFailure)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, blik, attempt: 1),
            Sent(.paymentDetailsEntered, blik, attempt: 1),
            Sent(.paymentProcessingStarted, blik, attempt: 1),
            Sent(.paymentSubmitted, blik, attempt: 1),
            Sent(.paymentFailure, blik, attempt: 1)
        ])
    }

    func test_retryAfterADecline_paysInASecondAttempt() async throws {
        repository.resumePaymentResult = .success(FormRedirectTestData.failedPaymentResponse)
        sut = try await makeSettledScope()
        try await selectBlikAndEnterCode().submit()
        try await funnel.waitFor(.paymentFailure)
        // The declined run must end before the retry can submit again.
        try await funnel.settle()

        repository.resumePaymentResult = .success(FormRedirectTestData.successPaymentResponse)
        sut.retryPayment()

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, blik, attempt: 1),
            Sent(.paymentDetailsEntered, blik, attempt: 1),
            Sent(.paymentProcessingStarted, blik, attempt: 1),
            Sent(.paymentSubmitted, blik, attempt: 1),
            Sent(.paymentFailure, blik, attempt: 1),
            Sent(.paymentReattempted, blik, attempt: 2),
            Sent(.paymentProcessingStarted, blik, attempt: 2),
            Sent(.paymentSubmitted, blik, attempt: 2),
            Sent(.paymentSuccess, blik, attempt: 2)
        ])
    }

    // MARK: - Helpers

    /// Picks BLIK from the list and types a full code, as the shopper does.
    private func selectBlikAndEnterCode() async throws -> DefaultFormRedirectScope {
        sut.paymentMethodSelection.onPaymentMethodSelected(paymentMethod: CheckoutPaymentMethod(id: blik, type: blik, name: "BLIK"))
        try await funnel.waitFor(.paymentMethodSelection)
        let form = try XCTUnwrap(sut.paymentMethodScopeCache[blik] as? DefaultFormRedirectScope)
        form.updateField(.otpCode, value: FormRedirectTestData.Constants.validBlikCode)
        try await funnel.waitFor(.paymentDetailsEntered)
        return form
    }

    // The shared BLIK mock is a web redirect, which the checkout would open as one.
    private func blikMethod() -> PrimerPaymentMethod {
        PrimerPaymentMethod(
            id: blik,
            implementationType: .nativeSdk,
            type: blik,
            name: "BLIK",
            processorConfigId: nil,
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
    }

    private func makeSettledScope(
        interactor: ProcessFormRedirectPaymentInteractor? = nil
    ) async throws -> DefaultCheckoutScope {
        // A second method keeps the list, so leaving BLIK returns to it instead of closing the checkout.
        SDKSessionHelper.setUp(withPaymentMethods: [blikMethod(), Mocks.PaymentMethods.paymentCardPaymentMethod])
        // The BLIK request reads the shopper's locale from the global settings.
        DependencyContainer.register(PrimerSettings() as PrimerSettingsProtocol)
        let container = try await ContainerTestHelpers.createTestContainer(
            apiConfiguration: PrimerAPIConfigurationModule.apiConfiguration,
            analyticsInteractor: funnel
        )
        let interactor: ProcessFormRedirectPaymentInteractor = interactor
            ?? ProcessFormRedirectPaymentInteractorImpl(formRedirectRepository: repository)
        _ = try await container.register(ProcessFormRedirectPaymentInteractor.self)
            .asSingleton()
            .with { _ in interactor }
        _ = try await container.register(ValidationService.self)
            .asSingleton()
            .with { _ in DefaultValidationService() }
        await DIContainer.setContainer(container)

        let scope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(uiOptions: PrimerUIOptions(isInitScreenEnabled: false)),
            navigator: CheckoutNavigator(coordinator: CheckoutCoordinator())
        )
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
