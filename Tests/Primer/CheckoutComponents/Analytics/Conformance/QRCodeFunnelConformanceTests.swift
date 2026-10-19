//
//  QRCodeFunnelConformanceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
import XCTest

/// The exact events a QR code payment sends, after the funnel rules. The shopper pays outside the SDK, so no SUBMITTED.
@available(iOS 15.0, *)
@MainActor
final class QRCodeFunnelConformanceTests: XCTestCase {

    private typealias Sent = FunnelAnalyticsInteractor.Sent

    private let payNow = PrimerPaymentMethodType.xfersPayNow.rawValue
    private let payNowMethod = PrimerPaymentMethod(
        id: "mock_xfers_paynow_id",
        implementationType: .nativeSdk,
        type: PrimerPaymentMethodType.xfersPayNow.rawValue,
        name: "PayNow",
        processorConfigId: nil,
        surcharge: nil,
        options: nil,
        displayMetadata: nil
    )
    private let funnel = FunnelAnalyticsInteractor()
    private let repository = MockQRCodeRepository()
    private var sut: DefaultCheckoutScope!
    private var integrationType: PrimerSDKIntegrationType?

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
        // A real CheckoutComponents session sets this when it starts.
        integrationType = PrimerInternal.shared.sdkIntegrationType
        PrimerInternal.shared.sdkIntegrationType = .checkoutComponents
        repository.startPaymentResult = .success(QRCodeTestData.defaultPaymentData)
        repository.pollResult = .success(QRCodeTestData.Constants.resumeToken)
        repository.resumePaymentResult = .success(QRCodeTestData.successPaymentResult)
    }

    override func tearDown() async throws {
        sut = nil
        PrimerInternal.shared.sdkIntegrationType = integrationType
        SDKSessionHelper.tearDown()
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_paymentConfirmedByPolling_sendsSuccessWithoutSubmitted() async throws {
        sut = try await makeSettledScope(paymentMethods: [payNowMethod])

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, payNow, attempt: 1),
            Sent(.paymentProcessingStarted, payNow, attempt: 1),
            Sent(.paymentSuccess, payNow, attempt: 1)
        ])
    }

    func test_closingTheShownQRCode_sendsUnselectedShopperCancel() async throws {
        // A second method gives the QR code screen a list to return to, so closing it keeps the checkout open.
        sut = try await makeSettledScope(
            paymentMethods: [payNowMethod, Mocks.PaymentMethods.paymentCardPaymentMethod],
            repository: ShownQRCodeRepository()
        )
        try await funnel.waitFor(.checkoutFlowStarted)
        sut.paymentMethodSelection.onPaymentMethodSelected(
            paymentMethod: CheckoutPaymentMethod(id: payNow, type: payNow, name: "PayNow")
        )
        let qrCode = try XCTUnwrap(sut.paymentMethodScopeCache[payNow] as? DefaultQRCodeScope)
        _ = try await awaitValue(qrCode.state, matching: { $0.status == .displaying })

        qrCode.cancel()

        try await funnel.waitFor(.paymentMethodUnselected)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, payNow, attempt: 1),
            Sent(.paymentProcessingStarted, payNow, attempt: 1),
            Sent(.paymentMethodUnselected, payNow, attempt: 1, reason: "shopper_cancel")
        ])
    }

    func test_declineReportedAfterPolling_sendsFailure() async throws {
        repository.resumePaymentResult = .failure(declined())
        sut = try await makeSettledScope(paymentMethods: [payNowMethod])

        try await funnel.waitFor(.paymentFailure)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, payNow, attempt: 1),
            Sent(.paymentProcessingStarted, payNow, attempt: 1),
            Sent(.paymentFailure, payNow, attempt: 1)
        ])
    }

    func test_retryAfterADecline_opensASecondAttempt() async throws {
        repository.resumePaymentResult = .failure(declined())
        sut = try await makeSettledScope(paymentMethods: [payNowMethod])
        try await funnel.waitFor(.paymentFailure)

        repository.resumePaymentResult = .success(QRCodeTestData.successPaymentResult)
        sut.retryPayment()

        try await funnel.waitFor(.paymentSuccess)
        try await funnel.settle()
        let sent = await funnel.sent
        XCTAssertEqual(sent, [
            Sent(.checkoutFlowStarted),
            Sent(.paymentMethodSelection, payNow, attempt: 1),
            Sent(.paymentProcessingStarted, payNow, attempt: 1),
            Sent(.paymentFailure, payNow, attempt: 1),
            Sent(.paymentReattempted, payNow, attempt: 2),
            Sent(.paymentProcessingStarted, payNow, attempt: 2),
            Sent(.paymentSuccess, payNow, attempt: 2)
        ])
    }

    // MARK: - Helpers

    private func declined() -> PrimerError {
        .paymentFailed(
            paymentMethodType: payNow,
            paymentId: QRCodeTestData.Constants.paymentId,
            orderId: nil,
            status: "DECLINED",
            diagnosticsId: "diag"
        )
    }

    private func makeSettledScope(
        paymentMethods: [PrimerPaymentMethod],
        repository: (any QRCodeRepository)? = nil
    ) async throws -> DefaultCheckoutScope {
        SDKSessionHelper.setUp(withPaymentMethods: paymentMethods)
        let container = try await ContainerTestHelpers.createTestContainer(
            apiConfiguration: PrimerAPIConfigurationModule.apiConfiguration,
            analyticsInteractor: funnel
        )
        let factory = QRCodePaymentInteractorFactory(repository: repository ?? self.repository)
        _ = try await container.register(QRCodePaymentInteractorFactory.self)
            .asSingleton()
            .with { _ in factory }
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

/// Keeps the QR code showing until polling is cancelled, then ends the poll the way the real repository does.
@available(iOS 15.0, *)
private final class ShownQRCodeRepository: QRCodeRepository {
    private let lock = NSLock()
    private var poll: CheckedContinuation<String, Error>?
    private var cancellation: PrimerError?

    func startPayment(paymentMethodType: String) async throws -> QRCodePaymentData {
        QRCodeTestData.defaultPaymentData
    }

    // The shopper can close the screen before the poll starts, so a cancel that came first ends it at once.
    func pollForCompletion(statusUrl: URL) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            defer { lock.unlock() }
            if let cancellation {
                continuation.resume(throwing: cancellation)
            } else {
                poll = continuation
            }
        }
    }

    func resumePayment(paymentId: String, resumeToken: String, paymentMethodType: String) async throws -> PaymentResult {
        QRCodeTestData.successPaymentResult
    }

    func cancelPolling(paymentMethodType: String) {
        let error = PrimerError.cancelled(paymentMethodType: paymentMethodType)
        lock.lock()
        defer { lock.unlock() }
        cancellation = error
        poll?.resume(throwing: error)
        poll = nil
    }
}
