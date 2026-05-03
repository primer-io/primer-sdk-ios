//
//  CheckoutAnalyticsTrackerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

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

    // MARK: - trackStateChange: ready

    func test_trackStateChange_ready_tracksCheckoutFlowStarted() async {
        // Given
        let state = PrimerCheckoutState.ready(totalAmount: 1000, currencyCode: "USD")

        // When
        await sut.trackStateChange(state)

        // Then
        let hasTracked = await mockAnalytics.hasTracked(.checkoutFlowStarted)
        XCTAssertTrue(hasTracked)
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

    func test_trackStateChange_failure_withPaymentFailed_tracksPaymentMetadata() async {
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
        XCTAssertEqual(events.first?.metadata?.paymentMethod, TestData.PaymentMethodTypes.card)
        XCTAssertEqual(events.first?.metadata?.paymentId, TestData.PaymentIds.success)
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

    func test_trackRetry_withFailureState_tracksPaymentReattempted() async {
        // Given
        let error = PrimerError.paymentFailed(
            paymentMethodType: TestData.PaymentMethodTypes.card,
            paymentId: TestData.PaymentIds.success,
            orderId: nil,
            status: "FAILED",
            diagnosticsId: "test_diagnostics"
        )

        // When
        await sut.trackRetry(navigationState: .failure(error))

        // Then
        let events = await mockAnalytics.trackedEvents
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.eventType, .paymentReattempted)
        XCTAssertEqual(events.first?.metadata?.paymentMethod, TestData.PaymentMethodTypes.card)
    }

    func test_trackRetry_withNonFailureState_tracksWithGeneralMetadata() async {
        // When
        await sut.trackRetry(navigationState: .loading)

        // Then
        let events = await mockAnalytics.trackedEvents
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.eventType, .paymentReattempted)
        XCTAssertNil(events.first?.metadata?.paymentMethod)
    }

    // MARK: - Nil interactor

    func test_trackStateChange_nilInteractor_doesNotCrash() async {
        // Given
        let tracker = CheckoutAnalyticsTracker(analyticsInteractor: nil)

        // When / Then — should not crash
        await tracker.trackStateChange(.ready(totalAmount: 1000, currencyCode: "USD"))
        await tracker.trackStateChange(.success(makePaymentResult()))
        await tracker.trackStateChange(.failure(makeError(message: "Error")))
        await tracker.trackStateChange(.dismissed)
    }
}
