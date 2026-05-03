//
//  CheckoutCoordinatorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
@MainActor
final class CheckoutCoordinatorTests: XCTestCase {

    private var sut: CheckoutCoordinator!

    override func setUp() async throws {
        try await super.setUp()
        sut = CheckoutCoordinator()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Navigation Behavior Tests

    func test_navigate_toPaymentMethod_pushesToStack() {
        // Given - navigate to payment selection first
        sut.navigate(to: .paymentMethodSelection)

        // When
        sut.navigate(to: .paymentMethod(TestData.PaymentMethodTypes.card, .fromPaymentSelection))

        // Then - pushed to stack
        XCTAssertEqual(sut.navigationStack.count, 2)
        XCTAssertEqual(sut.currentRoute, .paymentMethod(TestData.PaymentMethodTypes.card, .fromPaymentSelection))
    }

    func test_navigate_toProcessing_replacesCurrentRoute() {
        // Given - navigate to payment method first
        sut.navigate(to: .paymentMethodSelection)
        sut.navigate(to: .paymentMethod(TestData.PaymentMethodTypes.card, .fromPaymentSelection))
        XCTAssertEqual(sut.navigationStack.count, 2)

        // When
        sut.navigate(to: .processing)

        // Then - replaces payment method, stack count unchanged
        XCTAssertEqual(sut.navigationStack.count, 2)
        XCTAssertEqual(sut.currentRoute, .processing)
    }

    func test_navigate_toSameRoute_doesNotDuplicate() {
        // Given
        sut.navigate(to: .loading)

        // When - navigate to same route
        sut.navigate(to: .loading)

        // Then - still only one item
        XCTAssertEqual(sut.navigationStack.count, 1)
    }

    func test_navigate_toSplash_resetsEntireStack() {
        // Given - build up navigation stack
        sut.navigate(to: .loading)
        sut.navigate(to: .paymentMethodSelection)
        sut.navigate(to: .paymentMethod(TestData.PaymentMethodTypes.card, .fromPaymentSelection))

        // When
        sut.navigate(to: .splash)

        // Then - stack is completely cleared
        XCTAssertTrue(sut.navigationStack.isEmpty)
        XCTAssertEqual(sut.currentRoute, .splash)
    }

    // MARK: - GoBack Tests

    func test_goBack_removesLastRoute() {
        // Given
        sut.navigate(to: .paymentMethodSelection)
        sut.navigate(to: .paymentMethod(TestData.PaymentMethodTypes.card, .fromPaymentSelection))
        XCTAssertEqual(sut.navigationStack.count, 2)

        // When
        sut.goBack()

        // Then
        XCTAssertEqual(sut.navigationStack.count, 1)
        XCTAssertEqual(sut.currentRoute, .paymentMethodSelection)
    }

    func test_goBack_withEmptyStack_doesNothing() {
        // Given - empty stack

        // When
        sut.goBack()

        // Then - still empty, no crash
        XCTAssertTrue(sut.navigationStack.isEmpty)
    }

    func test_goBack_multipleTimes_removesMultipleRoutes() {
        // Given - build a deeper stack without replace behavior
        sut.navigate(to: .paymentMethodSelection) // reset -> 1 item
        sut.navigate(to: .paymentMethod(TestData.PaymentMethodTypes.card, .fromPaymentSelection)) // push -> 2 items
        sut.navigate(to: .paymentMethod(TestData.PaymentMethodTypes.applePay, .fromPaymentSelection)) // push -> 3 items

        // When
        sut.goBack() // -> 2 items
        sut.goBack() // -> 1 item

        // Then - back to payment method selection
        XCTAssertEqual(sut.navigationStack.count, 1)
        XCTAssertEqual(sut.currentRoute, .paymentMethodSelection)
    }

    // MARK: - LastPaymentMethodRoute Tests

    func test_lastPaymentMethodRoute_tracksPaymentMethod() {
        // Given
        sut.navigate(to: .paymentMethodSelection)
        let paymentRoute = CheckoutRoute.paymentMethod(TestData.PaymentMethodTypes.card, .fromPaymentSelection)
        sut.navigate(to: paymentRoute)

        // When - navigate away from payment method
        sut.navigate(to: .processing)

        // Then - last payment method is tracked
        XCTAssertEqual(sut.lastPaymentMethodRoute, paymentRoute)
    }

    // MARK: - Complex Navigation Flow Tests

    func test_fullCheckoutFlow_maintainsCorrectState() {
        // Simulate a complete checkout flow
        // 1. Initial state - splash
        XCTAssertEqual(sut.currentRoute, .splash)

        // 2. Loading
        sut.navigate(to: .loading)
        XCTAssertEqual(sut.currentRoute, .loading)

        // 3. Payment method selection
        sut.navigate(to: .paymentMethodSelection)
        XCTAssertEqual(sut.currentRoute, .paymentMethodSelection)

        // 4. Select card payment
        sut.navigate(to: .paymentMethod(TestData.PaymentMethodTypes.card, .fromPaymentSelection))
        XCTAssertEqual(sut.currentRoute, .paymentMethod(TestData.PaymentMethodTypes.card, .fromPaymentSelection))
        XCTAssertEqual(sut.navigationStack.count, 2)

        // 5. Processing
        sut.navigate(to: .processing)
        XCTAssertEqual(sut.currentRoute, .processing)
        XCTAssertEqual(sut.navigationStack.count, 2)

        // 6. Success
        let result = PaymentResult(paymentId: TestData.PaymentIds.success, status: .success)
        sut.navigate(to: .success(result))
        XCTAssertEqual(sut.currentRoute, .success(result))
    }

    func test_retryFlow_afterFailure() {
        // Simulate failure and retry
        // 1. Setup to processing
        sut.navigate(to: .paymentMethodSelection)
        sut.navigate(to: .paymentMethod(TestData.PaymentMethodTypes.card, .fromPaymentSelection))
        sut.navigate(to: .processing)

        // 2. Failure
        let error = PrimerError.invalidValue(key: TestData.ErrorKeys.test, value: nil, reason: nil, diagnosticsId: TestData.DiagnosticsIds.test)
        sut.handlePaymentFailure(error)
        XCTAssertEqual(sut.currentRoute, .failure(error))

        // 3. lastPaymentMethodRoute should be tracked
        XCTAssertEqual(sut.lastPaymentMethodRoute, .paymentMethod(TestData.PaymentMethodTypes.card, .fromPaymentSelection))

        // 4. User can navigate back to retry
        sut.navigate(to: .paymentMethodSelection)
        XCTAssertEqual(sut.currentRoute, .paymentMethodSelection)
    }
}
