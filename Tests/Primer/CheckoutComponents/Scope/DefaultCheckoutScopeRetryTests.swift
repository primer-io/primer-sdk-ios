//
//  DefaultCheckoutScopeRetryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
import XCTest

/// What the error screen's retry re-runs.
@available(iOS 15.0, *)
final class DefaultCheckoutScopeRetryTests: XCTestCase {

    private var sut: DefaultCheckoutScope!
    private var navigator: CheckoutNavigator!

    @MainActor
    override func setUp() {
        super.setUp()
        navigator = CheckoutNavigator()
    }

    @MainActor
    override func tearDown() {
        sut = nil
        navigator = nil
        super.tearDown()
    }

    @MainActor
    private func makeSut() -> DefaultCheckoutScope {
        DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            navigator: navigator
        )
    }

    private func makePaymentResult() -> PaymentResult {
        PaymentResult(paymentId: TestData.PaymentIds.success, status: .success)
    }

    @MainActor
    func test_retryPayment_afterCardPayment_resubmitsThatScope() {
        // Given
        sut = makeSut()
        let cardScope = MockPaymentMethodScope()
        sut.paymentMethodScopeCache[TestData.PaymentMethodTypes.card] = cardScope
        sut.updateNavigationState(.paymentMethod(TestData.PaymentMethodTypes.card))
        sut.startProcessing()

        // When
        sut.retryPayment()

        // Then
        XCTAssertEqual(cardScope.submitCallCount, 1)
    }

    // Regression: the retry target used to be read from `currentPaymentMethodScope`, which survives a
    // back-out to the selection screen. A saved-card payment that failed then re-submitted the card
    // form, and with a filled form that charges a different card than the one being retried.
    @MainActor
    func test_retryPayment_afterVaultedPayment_doesNotResubmitAStaleCardScope() {
        // Given — the customer opened the card form, went back, then paid with a saved card
        sut = makeSut()
        let cardScope = MockPaymentMethodScope()
        sut.paymentMethodScopeCache[TestData.PaymentMethodTypes.card] = cardScope
        sut.updateNavigationState(.paymentMethod(TestData.PaymentMethodTypes.card))
        sut.updateNavigationState(.paymentMethodSelection)
        sut.startProcessing()

        // When
        sut.retryPayment()

        // Then
        XCTAssertEqual(cardScope.submitCallCount, 0)
    }

    @MainActor
    func test_retryPayment_afterCvvRecapture_doesNotResubmitAStaleCardScope() {
        // Given
        sut = makeSut()
        let cardScope = MockPaymentMethodScope()
        sut.paymentMethodScopeCache[TestData.PaymentMethodTypes.card] = cardScope
        sut.updateNavigationState(.paymentMethod(TestData.PaymentMethodTypes.card))
        sut.updateNavigationState(.cvvRecapture)
        sut.startProcessing()

        // When
        sut.retryPayment()

        // Then
        XCTAssertEqual(cardScope.submitCallCount, 0)
    }

    @MainActor
    func test_retryPayment_afterSuccess_doesNothing() {
        // Given
        sut = makeSut()
        let cardScope = MockPaymentMethodScope()
        sut.paymentMethodScopeCache[TestData.PaymentMethodTypes.card] = cardScope
        sut.updateNavigationState(.paymentMethod(TestData.PaymentMethodTypes.card))
        sut.startProcessing()
        sut.updateNavigationState(.success(makePaymentResult()))

        // When
        sut.retryPayment()

        // Then
        XCTAssertEqual(cardScope.submitCallCount, 0)
    }

    @MainActor
    func test_retryPayment_afterFailure_stillTargetsTheFailedAttempt() {
        // Given
        sut = makeSut()
        let cardScope = MockPaymentMethodScope()
        sut.paymentMethodScopeCache[TestData.PaymentMethodTypes.card] = cardScope
        sut.updateNavigationState(.paymentMethod(TestData.PaymentMethodTypes.card))
        sut.startProcessing()
        sut.updateNavigationState(.failure(PrimerError.unknown(message: "declined")))

        // When
        sut.retryPayment()

        // Then
        XCTAssertEqual(cardScope.submitCallCount, 1)
    }
}
