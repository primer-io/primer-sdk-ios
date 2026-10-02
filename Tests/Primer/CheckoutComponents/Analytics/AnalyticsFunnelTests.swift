//
//  AnalyticsFunnelTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) @testable import PrimerFoundation
@testable import PrimerSDK
import XCTest

/// The event type and payload each typed call of the funnel sends.
@available(iOS 15.0, *)
final class AnalyticsFunnelTests: XCTestCase {

    private var sut: MockTrackingAnalyticsInteractor!

    override func setUp() {
        super.setUp()
        sut = MockTrackingAnalyticsInteractor()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_lifecycleCalls_sendTheirEventsWithoutAPaymentMethod() async {
        // When
        await sut.trackSDKInitStart()
        await sut.trackSDKInitEnd()
        await sut.trackReattempted()
        await sut.trackFlowExited()

        // Then
        let events = await sut.trackedEvents
        XCTAssertEqual(events.map(\.eventType), [.sdkInitStart, .sdkInitEnd, .paymentReattempted, .paymentFlowExited])
        XCTAssertTrue(events.allSatisfy { $0.metadata == nil })
    }

    func test_checkoutFlowStarted_carriesTheAvailablePaymentMethods() async {
        // When
        await sut.trackCheckoutFlowStarted(availablePaymentMethods: ["PAYMENT_CARD", "PAYPAL"])

        // Then
        let events = await sut.trackedEvents
        XCTAssertEqual(events.map(\.eventType), [.checkoutFlowStarted])
        XCTAssertEqual(events.first?.metadata?.availablePaymentMethods, ["PAYMENT_CARD", "PAYPAL"])
    }

    func test_paymentMethodCalls_carryThePaymentMethod() async {
        // When
        await sut.trackMethodSelected("PAYPAL")
        await sut.trackDetailsEntered("PAYPAL")
        await sut.trackProcessingStarted("PAYPAL")
        await sut.trackSubmitted("PAYPAL")
        await sut.trackRedirectReturnUrlNotConfigured("PAYPAL")

        // Then
        let events = await sut.trackedEvents
        XCTAssertEqual(
            events.map(\.eventType),
            [.paymentMethodSelection, .paymentDetailsEntered, .paymentProcessingStarted, .paymentSubmitted, .redirectReturnUrlNotConfigured]
        )
        XCTAssertEqual(events.map { $0.metadata?.paymentMethod }, Array(repeating: "PAYPAL", count: 5))
    }

    func test_methodUnselected_carriesTheReason() async {
        // When
        await sut.trackMethodUnselected("PAYMENT_CARD", reason: .merchantAbort)

        // Then
        let events = await sut.trackedEvents
        XCTAssertEqual(events.map(\.eventType), [.paymentMethodUnselected])
        XCTAssertEqual(events.first?.metadata?.paymentMethod, "PAYMENT_CARD")
        XCTAssertEqual(events.first?.metadata?.paymentEvent?.reason, "merchant_abort")
    }

    func test_methodUnselected_withoutAMethod_leavesItToTheOpenAttempt() async {
        // When
        await sut.trackMethodUnselected(nil, reason: .shopperCancel)

        // Then
        let events = await sut.trackedEvents
        XCTAssertNil(events.first?.metadata?.paymentMethod)
        XCTAssertEqual(events.first?.metadata?.paymentEvent?.reason, "shopper_cancel")
    }

    func test_redirectToThirdParty_sendsOnlyTheOriginOfThePage() async throws {
        // When
        let page = try XCTUnwrap(URL(string: "https://bank.example.com/pay?token=secret"))
        await sut.trackRedirectToThirdParty("ADYEN_IDEAL", destination: page, paymentId: "pay_1")

        // Then
        let events = await sut.trackedEvents
        XCTAssertEqual(events.map(\.eventType), [.paymentRedirectToThirdParty])
        XCTAssertEqual(events.first?.metadata?.paymentMethod, "ADYEN_IDEAL")
        XCTAssertEqual(events.first?.metadata?.redirectDestinationUrl, "https://bank.example.com")
        XCTAssertEqual(events.first?.metadata?.paymentId, "pay_1")
    }

    func test_returned_sendsTheReturnAndThenSubmitted() async {
        // When
        await sut.trackReturned("ADYEN_IDEAL", paymentId: "pay_1")

        // Then
        let events = await sut.trackedEvents
        XCTAssertEqual(events.map(\.eventType), [.paymentReturnedFromThirdParty, .paymentSubmitted])
        XCTAssertEqual(events.first?.metadata?.paymentId, "pay_1")
        XCTAssertEqual(events.map { $0.metadata?.paymentMethod }, ["ADYEN_IDEAL", "ADYEN_IDEAL"])
    }

    func test_success_carriesThePaymentMethodAndThePayment() async {
        // When
        await sut.trackSuccess("PAYMENT_CARD", paymentId: "pay_1")

        // Then
        let events = await sut.trackedEvents
        XCTAssertEqual(events.map(\.eventType), [.paymentSuccess])
        XCTAssertEqual(events.first?.metadata?.paymentMethod, "PAYMENT_CARD")
        XCTAssertEqual(events.first?.metadata?.paymentId, "pay_1")
    }

    func test_success_withoutAPaymentMethod_sendsGeneralMetadata() async {
        // When
        await sut.trackSuccess(nil, paymentId: "pay_1")

        // Then
        let events = await sut.trackedEvents
        XCTAssertEqual(events.map(\.eventType), [.paymentSuccess])
        XCTAssertNil(events.first?.metadata?.paymentMethod)
        XCTAssertNil(events.first?.metadata?.paymentEvent)
    }

    func test_failure_carriesTheErrorCodeOriginAndOutcome() async {
        // Given
        let error = PrimerError.paymentFailed(paymentMethodType: "PAYMENT_CARD", paymentId: "pay_1", orderId: nil, status: "DECLINED")

        // When
        await sut.trackFailure(error, paymentMethod: "PAYMENT_CARD", paymentId: "pay_1")

        // Then
        let events = await sut.trackedEvents
        XCTAssertEqual(events.map(\.eventType), [.paymentFailure])
        let payment = events.first?.metadata?.paymentEvent
        XCTAssertEqual(payment?.paymentMethod, "PAYMENT_CARD")
        XCTAssertEqual(payment?.paymentId, "pay_1")
        XCTAssertEqual(payment?.errorCode, error.errorId)
        XCTAssertEqual(payment?.errorOrigin, "payment")
        XCTAssertEqual(payment?.outcome, "failed")
    }

    func test_analyticsOrigin_groupsErrorsByWhoCausedThem() {
        XCTAssertEqual(
            PrimerError.paymentFailed(paymentMethodType: nil, paymentId: "pay_1", orderId: nil, status: "FAILED").analyticsOrigin,
            .payment
        )
        XCTAssertEqual(PrimerError.invalidClientToken().analyticsOrigin, .integration)
        XCTAssertEqual(PrimerError.merchantError(message: "aborted").analyticsOrigin, .integration)
        XCTAssertEqual(PrimerError.unknown(message: "unexpected").analyticsOrigin, .primer)
    }
}
