//
//  PaymentFailureTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
@MainActor
final class PaymentFailureTests: XCTestCase {

    private var result: Result<PaymentResult, Error>?

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
    }

    override func tearDown() async throws {
        result = nil
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    // MARK: - failedPaymentCheckoutData

    func test_failedPaymentCheckoutData_paymentFailed_carriesPaymentIdOrderIdAndStatus() {
        let error = PrimerError.paymentFailed(
            paymentMethodType: "PAYMENT_CARD", paymentId: TestData.PaymentIds.failed, orderId: "order-1", status: "FAILED"
        )

        let payment = error.failedPaymentCheckoutData?.payment

        XCTAssertEqual(payment?.id, TestData.PaymentIds.failed)
        XCTAssertEqual(payment?.orderId, "order-1")
        XCTAssertEqual(payment?.status, "FAILED")
    }

    func test_failedPaymentCheckoutData_placeholderPaymentId_isNil() {
        for paymentId in ["unknown", ""] {
            let error = PrimerError.paymentFailed(
                paymentMethodType: "PAYMENT_CARD", paymentId: paymentId, orderId: nil, status: "FAILED"
            )
            XCTAssertNil(error.failedPaymentCheckoutData, paymentId)
        }
    }

    func test_failedPaymentCheckoutData_otherError_isNil() {
        XCTAssertNil(PrimerError.unknown(message: "boom").failedPaymentCheckoutData)
    }

    // MARK: - init(unwrapping:)

    func test_paymentFailure_wrappedError_keepsCheckoutData() {
        let checkoutData = makeCheckoutData()
        let error: Error = PaymentFailure(error: .unknown(message: "boom"), checkoutData: checkoutData)

        XCTAssertTrue(PaymentFailure(unwrapping: error).checkoutData === checkoutData)
    }

    func test_paymentFailure_primerError_hasNoCheckoutData() {
        let error: Error = PrimerError.invalidClientToken()

        XCTAssertEqual(PaymentFailure(unwrapping: error).error.errorId, "invalid-client-token")
        XCTAssertNil(PaymentFailure(unwrapping: error).checkoutData)
    }

    func test_paymentFailure_foreignError_becomesUnknown() {
        let error: Error = NSError(domain: "test", code: 1)

        XCTAssertEqual(PaymentFailure(unwrapping: error).error.errorId, "unknown")
    }

    // MARK: - PaymentCompletionHandler

    func test_completionHandler_didFail_forwardsCheckoutData() {
        let checkoutData = makeCheckoutData()

        let failure = failure(reportedBy: makeHandler(), checkoutData: checkoutData)

        XCTAssertTrue(failure?.checkoutData === checkoutData)
    }

    func test_completionHandler_didFail_dropsPreviousAttemptsCheckoutData() {
        let previous = makeCheckoutData()

        let failure = failure(reportedBy: makeHandler(staleCheckoutData: previous), checkoutData: previous)

        XCTAssertNotNil(failure)
        XCTAssertNil(failure?.checkoutData)
    }

    // MARK: - DefaultCheckoutScope.handlePaymentError

    func test_handlePaymentError_withCheckoutData_carriesItOnStateAndNavigation() {
        let sut = makeCheckoutScope()
        let checkoutData = makeCheckoutData()

        sut.handlePaymentError(.unknown(message: "3DS failed"), checkoutData: checkoutData)

        guard case let .failure(_, stateData) = sut.currentState,
              case let .failure(_, navigationData) = sut.navigationState else {
            return XCTFail("Expected failure state and navigation")
        }
        XCTAssertTrue(stateData === checkoutData)
        XCTAssertTrue(navigationData === checkoutData)
    }

    func test_handlePaymentError_paymentFailed_prefersDeclineOverSnapshot() {
        let sut = makeCheckoutScope()
        let error = PrimerError.paymentFailed(
            paymentMethodType: "PAYMENT_CARD", paymentId: TestData.PaymentIds.failed, orderId: "order-2", status: "FAILED"
        )

        sut.handlePaymentError(error, checkoutData: makeCheckoutData())

        guard case let .failure(_, checkoutData) = sut.navigationState else {
            return XCTFail("Expected navigation state to be failure")
        }
        XCTAssertEqual(checkoutData?.payment?.id, TestData.PaymentIds.failed)
        XCTAssertEqual(checkoutData?.payment?.orderId, "order-2")
        XCTAssertEqual(checkoutData?.payment?.status, "FAILED")
    }

    func test_handlePaymentError_beforePaymentExists_hasNoCheckoutData() {
        let sut = makeCheckoutScope()

        sut.handlePaymentError(.invalidClientToken())

        guard case let .failure(_, checkoutData) = sut.navigationState else {
            return XCTFail("Expected navigation state to be failure")
        }
        XCTAssertNil(checkoutData)
    }

    // MARK: - Helpers

    private func makeHandler(staleCheckoutData: PrimerCheckoutData? = nil) -> PaymentCompletionHandler {
        PaymentCompletionHandler(staleCheckoutData: staleCheckoutData) { [weak self] in
            self?.result = $0
        }
    }

    private func failure(reportedBy handler: PaymentCompletionHandler, checkoutData: PrimerCheckoutData?) -> PaymentFailure? {
        handler.primerHeadlessUniversalCheckoutDidFail(withError: PrimerError.unknown(message: "boom"), checkoutData: checkoutData)
        guard case let .failure(error) = result else { return nil }
        return error as? PaymentFailure
    }

    private func makeCheckoutScope() -> DefaultCheckoutScope {
        DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            navigator: CheckoutNavigator(coordinator: CheckoutCoordinator())
        )
    }

    private func makeCheckoutData() -> PrimerCheckoutData {
        PrimerCheckoutData(
            payment: PrimerCheckoutDataPayment(
                id: TestData.PaymentIds.pending, orderId: "order-1", paymentFailureReason: nil, status: "PENDING"
            )
        )
    }
}
