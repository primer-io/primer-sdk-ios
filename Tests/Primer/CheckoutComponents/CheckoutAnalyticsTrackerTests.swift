//
//  CheckoutAnalyticsTrackerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
@MainActor
final class CheckoutAnalyticsTrackerTests: XCTestCase {

    private var sut: CheckoutAnalyticsTracker!
    private var mockAnalytics: MockTrackingAnalyticsInteractor!

    override func setUp() {
        super.setUp()
        mockAnalytics = MockTrackingAnalyticsInteractor()
        sut = CheckoutAnalyticsTracker(analyticsInteractor: mockAnalytics)
    }

    override func tearDown() {
        sut = nil
        mockAnalytics = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makePaymentResult(
        paymentId: String = TestData.PaymentIds.success,
        paymentMethodType: String? = nil
    ) -> PaymentResult {
        PaymentResult(paymentId: paymentId, status: .success, paymentMethodType: paymentMethodType)
    }

    private func makeError(message: String) -> PrimerError {
        PrimerError.unknown(message: message, diagnosticsId: "test_diagnostics")
    }

    private func makeClientSession(totalAmount: Int = 1000, currencyCode: String = "USD") -> PrimerClientSession {
        PrimerClientSession(
            customerId: nil,
            orderId: nil,
            currencyCode: currencyCode,
            totalAmount: totalAmount,
            lineItems: nil,
            orderDetails: nil,
            customer: nil,
            paymentMethod: nil,
            fees: nil
        )
    }

    // MARK: - trackStateChange: ready

    func test_trackStateChange_ready_tracksCheckoutFlowStartedWithAvailablePaymentMethods() async {
        // Given
        let state = PrimerCheckoutState.ready(clientSession: makeClientSession())
        let methods = [TestData.PaymentMethodTypes.card, TestData.PaymentMethodTypes.paypal]

        // When
        await sut.trackStateChange(state, availablePaymentMethods: methods)

        // Then
        let events = await mockAnalytics.trackedEvents
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.eventType, .checkoutFlowStarted)
        XCTAssertEqual(events.first?.metadata?.availablePaymentMethods, methods)
    }

    // MARK: - trackStateChange: success

    func test_trackStateChange_success_withPaymentMethodType_tracksPaymentSuccessWithMetadata() async {
        // Given
        let result = makePaymentResult(paymentMethodType: TestData.PaymentMethodTypes.card)

        // When
        await sut.trackStateChange(.success(result))

        // Then
        let events = await mockAnalytics.trackedEvents
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.eventType, .paymentSuccess)
        XCTAssertEqual(events.first?.metadata?.paymentMethod, TestData.PaymentMethodTypes.card)
        XCTAssertEqual(events.first?.metadata?.paymentId, TestData.PaymentIds.success)
    }

    func test_trackStateChange_success_withoutPaymentMethodType_tracksPaymentSuccessWithGeneralMetadata() async {
        // Given
        let result = makePaymentResult()

        // When
        await sut.trackStateChange(.success(result))

        // Then
        let events = await mockAnalytics.trackedEvents
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.eventType, .paymentSuccess)
        XCTAssertNil(events.first?.metadata?.paymentMethod)
    }

    // MARK: - trackStateChange: failure

    func test_trackStateChange_failure_tracksPaymentFailure() async {
        // Given
        let error = makeError(message: "Payment failed")

        // When
        await sut.trackStateChange(.failure(error))

        // Then
        let hasTracked = await mockAnalytics.hasTracked(.paymentFailure)
        XCTAssertTrue(hasTracked)
    }

    func test_trackStateChange_failure_withPaymentFailed_tracksErrorDetails() async {
        // Given
        let error = PrimerError.paymentFailed(
            paymentMethodType: TestData.PaymentMethodTypes.card,
            paymentId: TestData.PaymentIds.success,
            orderId: nil,
            status: "FAILED",
            diagnosticsId: "test_diagnostics"
        )

        // When
        await sut.trackStateChange(.failure(error))

        // Then
        let events = await mockAnalytics.trackedEvents
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.eventType, .paymentFailure)
        let payment = events.first?.metadata?.paymentEvent
        XCTAssertEqual(payment?.paymentMethod, TestData.PaymentMethodTypes.card)
        XCTAssertEqual(payment?.paymentId, TestData.PaymentIds.success)
        XCTAssertEqual(payment?.errorCode, "payment-failed")
        XCTAssertEqual(payment?.errorOrigin, "payment")
        XCTAssertEqual(payment?.outcome, "failed")
    }

    // The shared vault flow reports UNKNOWN when its token has no payment method type.
    func test_trackStateChange_failureWithAnUnknownMethod_sendsTheAttemptsMethod() async {
        // Given
        let funnel = FunnelAnalyticsInteractor()
        let tracker = CheckoutAnalyticsTracker(analyticsInteractor: funnel)
        await funnel.trackMethodSelected(TestData.PaymentMethodTypes.card)
        let error = PrimerError.paymentFailed(
            paymentMethodType: "UNKNOWN",
            paymentId: TestData.PaymentIds.success,
            orderId: nil,
            status: "FAILED",
            diagnosticsId: "test_diagnostics"
        )

        // When
        await tracker.trackStateChange(.failure(error))

        // Then
        let sent = await funnel.sent
        XCTAssertEqual(sent.last, FunnelAnalyticsInteractor.Sent(.paymentFailure, TestData.PaymentMethodTypes.card, attempt: 1))
    }

    func test_trackStateChange_failure_takesThePaymentIdFromCheckoutData() async {
        // Given
        let checkoutData = PrimerCheckoutData(
            payment: PrimerCheckoutDataPayment(id: "pay_declined", orderId: nil, paymentFailureReason: nil, status: "DECLINED")
        )

        // When
        await sut.trackStateChange(.failure(makeError(message: "Declined"), checkoutData: checkoutData))

        // Then
        let paymentId = await mockAnalytics.trackedEvents.first?.metadata?.paymentEvent?.paymentId
        XCTAssertEqual(paymentId, "pay_declined")
    }

    // MARK: - trackStateChange: dismissed

    func test_trackStateChange_dismissed_tracksPaymentFlowExited() async {
        // When
        await sut.trackStateChange(.dismissed)

        // Then
        let hasTracked = await mockAnalytics.hasTracked(.paymentFlowExited)
        XCTAssertTrue(hasTracked)
    }

    // MARK: - trackStateChange: initializing

    func test_trackStateChange_initializing_doesNotTrack() async {
        // When
        await sut.trackStateChange(.initializing)

        // Then
        let count = await mockAnalytics.trackEventCallCount
        XCTAssertEqual(count, 0)
    }

    // MARK: - trackRetry

    func test_trackRetry_tracksPaymentReattempted() async {
        // When
        await sut.trackRetry()

        // Then
        let events = await mockAnalytics.trackedEvents
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.eventType, .paymentReattempted)
        XCTAssertNil(events.first?.metadata)
    }

    // MARK: - trackNavigation

    func test_trackNavigation_fromPaymentMethodToSelection_tracksUnselectedWithShopperCancelReason() async {
        // When
        await sut.trackNavigation(from: .paymentMethod(TestData.PaymentMethodTypes.card), to: .paymentMethodSelection)

        // Then
        let events = await mockAnalytics.trackedEvents
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.eventType, .paymentMethodUnselected)
        XCTAssertEqual(events.first?.metadata?.paymentMethod, TestData.PaymentMethodTypes.card)
        XCTAssertEqual(
            events.first?.metadata?.paymentEvent?.reason,
            AnalyticsContract.UnselectReason.shopperCancel.rawValue
        )
    }

    func test_trackNavigation_otherTransitions_tracksNothing() async {
        // When
        await sut.trackNavigation(from: .loading, to: .paymentMethodSelection)
        await sut.trackNavigation(from: .paymentMethod(TestData.PaymentMethodTypes.klarna), to: .cvvRecapture)
        await sut.trackNavigation(from: .paymentMethodSelection, to: .paymentMethod(TestData.PaymentMethodTypes.paypal))

        // Then
        let count = await mockAnalytics.trackEventCallCount
        XCTAssertEqual(count, 0)
    }

    // MARK: - Payment outcome log

    func test_failureLogFields_withCreatedPayment_includesCheckoutFailureOutcome() {
        // Given
        let error = PrimerError.paymentFailed(paymentMethodType: "PAYMENT_CARD", paymentId: "pay_123", orderId: nil, status: "DECLINED")
        let checkoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(id: "pay_123", orderId: nil, paymentFailureReason: nil, status: "DECLINED"))

        // When
        let fields = CheckoutAnalyticsTracker.failureLogFields(error, checkoutData: checkoutData)

        // Then
        XCTAssertEqual(fields["checkout_outcome"] as? String, "CHECKOUT_FAILURE")
        XCTAssertEqual(fields["error_code"] as? String, "PAYMENT_FAILED")
        XCTAssertEqual(fields["error_origin"] as? String, "payment")
        XCTAssertEqual(fields["diagnostics_id"] as? String, error.diagnosticsId)
        XCTAssertNotNil(fields["error_message"])
    }

    func test_failureLogFields_withoutPayment_omitsCheckoutOutcome() {
        // When
        let fields = CheckoutAnalyticsTracker.failureLogFields(.cancelled(paymentMethodType: "PAYPAL"), checkoutData: nil)

        // Then
        XCTAssertNil(fields["checkout_outcome"])
        XCTAssertEqual(fields["error_code"] as? String, "PAYMENT_CANCELLED")
    }

    func test_datadogErrorCode_matchesWebCodesAndFallsBackToErrorId() {
        let expected: [(PrimerError, String)] = [
            (.paymentFailed(paymentMethodType: "PAYMENT_CARD", paymentId: "pay_123", orderId: nil, status: "DECLINED"), "PAYMENT_FAILED"),
            (.cancelled(paymentMethodType: "PAYPAL"), "PAYMENT_CANCELLED"),
            (.merchantError(message: "abort"), "PAYMENT_CREATION_ABORTED"),
            (.failedToResumePayment(paymentMethodType: "PAYMENT_CARD", description: "resume"), "RESUME_FAILED"),
            (.invalidClientToken(reason: "expired"), "INVALID_CLIENT_TOKEN"),
            (.unknown(message: "boom"), "UNEXPECTED"),
            (.applePayTimedOut(), "APPLE_PAY_TIMED_OUT")
        ]

        for (error, code) in expected {
            XCTAssertEqual(error.datadogErrorCode, code, "\(error.errorId)")
        }
    }

    // MARK: - Nil interactor

    func test_trackStateChange_nilInteractor_doesNotCrash() async {
        // Given
        let tracker = CheckoutAnalyticsTracker(analyticsInteractor: nil)

        // When / Then — should not crash
        await tracker.trackStateChange(.ready(clientSession: makeClientSession()))
        await tracker.trackStateChange(.success(makePaymentResult()))
        await tracker.trackStateChange(.failure(makeError(message: "Error")))
        await tracker.trackStateChange(.dismissed)
    }
}
