//
//  AchFunnelConformanceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
import XCTest

/// The exact events a Stripe ACH checkout sends, after the funnel rules.
@available(iOS 15.0, *)
@MainActor
final class AchFunnelConformanceTests: XCTestCase {

    private typealias Sent = FunnelAnalyticsInteractor.Sent

    private let ach = PrimerPaymentMethodType.stripeAch.rawValue
    private let achMethod = PrimerPaymentMethod(
        id: "stripe_ach",
        implementationType: .nativeSdk,
        type: PrimerPaymentMethodType.stripeAch.rawValue,
        name: "ACH",
        processorConfigId: nil,
        surcharge: nil,
        options: nil,
        displayMetadata: nil
    )
    private let funnel = FunnelAnalyticsInteractor()
    private let interactor = MockProcessAchPaymentInteractor.withFullSuccessFlow()
    private var sut: DefaultCheckoutScope!
    private var integrationType: PrimerSDKIntegrationType?

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
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

    func test_acceptingTheMandate_isSubmittedAndPaid() async throws {
        sut = try await makeSettledScope(paymentMethods: [achMethod])
        let scope = try achScope()
        try await reachMandate(scope)

        scope.acceptMandate()

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, ach, attempt: 1),
            Sent(.paymentProcessingStarted, ach, attempt: 1),
            Sent(.paymentSubmitted, ach, attempt: 1),
            Sent(.paymentSuccess, ach, attempt: 1)
        ])
    }

    // From the list, so declining returns there instead of closing the checkout.
    func test_decliningTheMandate_unselectsTheMethod() async throws {
        sut = try await makeSettledScope(paymentMethods: [Mocks.PaymentMethods.paymentCardPaymentMethod, achMethod])
        try await funnel.waitFor(.checkoutFlowStarted)
        sut.paymentMethodSelection.onPaymentMethodSelected(paymentMethod: CheckoutPaymentMethod(id: ach, type: ach, name: "ACH"))
        let scope = try achScope()
        try await reachMandate(scope)

        scope.declineMandate()

        try await funnel.waitFor(.paymentMethodUnselected)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, ach, attempt: 1),
            Sent(.paymentMethodUnselected, ach, attempt: 1, reason: "shopper_cancel")
        ])
    }

    func test_declinedPayment_isAFailure() async throws {
        interactor.completePaymentError = declined()
        sut = try await makeSettledScope(paymentMethods: [achMethod])
        let scope = try achScope()
        try await reachMandate(scope)

        scope.acceptMandate()

        try await funnel.waitFor(.paymentFailure)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, ach, attempt: 1),
            Sent(.paymentProcessingStarted, ach, attempt: 1),
            Sent(.paymentSubmitted, ach, attempt: 1),
            Sent(.paymentFailure, ach, attempt: 1)
        ])
    }

    func test_retryAfterADeclinedPayment_isASecondAttempt() async throws {
        interactor.completePaymentError = declined()
        sut = try await makeSettledScope(paymentMethods: [achMethod])
        let scope = try achScope()
        try await reachMandate(scope)
        scope.acceptMandate()
        try await funnel.waitFor(.paymentFailure)

        interactor.completePaymentError = nil
        sut.retryPayment()
        try await funnel.waitFor(.paymentReattempted)
        try await reachMandate(scope)
        scope.acceptMandate()

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, ach, attempt: 1),
            Sent(.paymentProcessingStarted, ach, attempt: 1),
            Sent(.paymentSubmitted, ach, attempt: 1),
            Sent(.paymentFailure, ach, attempt: 1),
            Sent(.paymentReattempted, ach, attempt: 2),
            Sent(.paymentProcessingStarted, ach, attempt: 2),
            Sent(.paymentSubmitted, ach, attempt: 2),
            Sent(.paymentSuccess, ach, attempt: 2)
        ])
    }

    // MARK: - Helpers

    private func declined() -> PrimerError {
        .paymentFailed(
            paymentMethodType: ach,
            paymentId: AchTestData.Constants.paymentId,
            orderId: nil,
            status: "DECLINED",
            diagnosticsId: "diag"
        )
    }

    // In debug builds the test ACH type is cached too, so look the scope up by its type.
    private func achScope() throws -> DefaultAchScope {
        try XCTUnwrap(sut.paymentMethodScopeCache[ach] as? DefaultAchScope)
    }

    private func reachMandate(_ scope: DefaultAchScope) async throws {
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })
        scope.submitUserDetails()
        _ = try await awaitValue(scope.state, matching: { $0.step == .bankAccountCollection })
        scope.achBankCollectorDidSucceed(paymentId: AchTestData.Constants.paymentId)
        _ = try await awaitValue(scope.state, matching: { $0.step == .mandateAcceptance })
    }

    private func makeSettledScope(paymentMethods: [PrimerPaymentMethod]) async throws -> DefaultCheckoutScope {
        SDKSessionHelper.setUp(withPaymentMethods: paymentMethods)
        let container = try await ContainerTestHelpers.createTestContainer(
            apiConfiguration: PrimerAPIConfigurationModule.apiConfiguration,
            analyticsInteractor: funnel
        )
        _ = try await container.register(ProcessAchPaymentInteractor.self)
            .asSingleton()
            .with { [interactor] _ in interactor }
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
