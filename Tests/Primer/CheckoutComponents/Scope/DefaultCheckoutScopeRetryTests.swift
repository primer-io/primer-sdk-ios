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
    private var cardScope: MockPaymentMethodScope!
    private var selection: MockSelectionScopeInternal!

    @MainActor
    override func setUp() {
        super.setUp()
        navigator = CheckoutNavigator()
        cardScope = MockPaymentMethodScope()
        selection = MockSelectionScopeInternal()
        sut = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            navigator: navigator
        )
        sut.cachedPaymentMethodSelection = selection
    }

    @MainActor
    override func tearDown() {
        sut = nil
        navigator = nil
        cardScope = nil
        selection = nil
        super.tearDown()
    }

    @MainActor
    func test_retryPayment_withNothingAttempted_doesNothing() {
        sut.retryPayment()

        XCTAssertEqual(cardScope.submitCallCount, 0)
        XCTAssertFalse(selection.paidWithVaulted)
    }

    @MainActor
    func test_retryPayment_afterACardPayment_resubmitsThatScope() {
        sut.updateNavigationState(.paymentMethod(TestData.PaymentMethodTypes.card))
        sut.startProcessing(payingWith: cardScope)

        sut.retryPayment()

        XCTAssertEqual(cardScope.submitCallCount, 1)
        XCTAssertFalse(selection.paidWithVaulted)
    }

    // The inline flow never leaves `.paymentMethodSelection`, because the merchant renders the card
    // form on their own screen. Reading the attempt off the navigation state would call the vault.
    @MainActor
    func test_retryPayment_afterAnInlineCardPayment_resubmitsThatScope() {
        sut.updateNavigationState(.paymentMethodSelection)
        sut.startProcessing(payingWith: cardScope)

        sut.retryPayment()

        XCTAssertEqual(cardScope.submitCallCount, 1)
        XCTAssertFalse(selection.paidWithVaulted)
    }

    @MainActor
    func test_retryPayment_afterASavedCardPayment_paysWithTheSavedCardAgain() async {
        sut.startProcessing(payingWith: nil)

        sut.retryPayment()
        await Task.yield()

        XCTAssertTrue(selection.paidWithVaulted)
        XCTAssertEqual(cardScope.submitCallCount, 0)
    }

    // Regression: the retry target used to be read from the scope of the last payment-method screen
    // opened, which is never cleared on the way back to selection. A saved-card payment that failed
    // then re-submitted the card form, and with a filled form charged a different card.
    @MainActor
    func test_retryPayment_afterBrowsingTheCardFormThenPayingWithASavedCard_doesNotResubmitTheForm() async {
        sut.updateNavigationState(.paymentMethod(TestData.PaymentMethodTypes.card))
        sut.updateNavigationState(.paymentMethodSelection)
        sut.startProcessing(payingWith: nil)

        sut.retryPayment()
        await Task.yield()

        XCTAssertEqual(cardScope.submitCallCount, 0)
        XCTAssertTrue(selection.paidWithVaulted)
    }

    // The CVV screen pays through the same vault entry point, so a retry asks for the code again
    // rather than reusing one the SDK would have had to keep.
    @MainActor
    func test_retryPayment_afterCvvRecapture_paysWithTheSavedCardAgain() async {
        sut.updateNavigationState(.cvvRecapture)
        sut.startProcessing(payingWith: nil)

        sut.retryPayment()
        await Task.yield()

        XCTAssertTrue(selection.paidWithVaulted)
    }

    @MainActor
    func test_retryPayment_afterSuccess_doesNothing() {
        sut.startProcessing(payingWith: cardScope)
        sut.updateNavigationState(.success(PaymentResult(paymentId: TestData.PaymentIds.success, status: .success)))

        sut.retryPayment()

        XCTAssertEqual(cardScope.submitCallCount, 0)
    }

    @MainActor
    func test_retryPayment_afterFailure_stillTargetsTheFailedAttempt() {
        sut.startProcessing(payingWith: cardScope)
        sut.updateNavigationState(.failure(PrimerError.unknown(message: "declined")))

        sut.retryPayment()

        XCTAssertEqual(cardScope.submitCallCount, 1)
    }
}
