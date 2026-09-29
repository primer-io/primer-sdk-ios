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
@MainActor
final class DefaultCheckoutScopeRetryTests: XCTestCase {

    private var sut: DefaultCheckoutScope!
    private var navigator: CheckoutNavigator!
    private var cardScope: MockPaymentMethodScope!
    private var qrScope: MockPaymentMethodScope!
    private var selection: MockSelectionScopeInternal!
    private let card = InternalPaymentMethod(id: "card", type: TestData.PaymentMethodTypes.card, name: "Card")
    private let qrMethod = InternalPaymentMethod(id: "qr", type: PrimerPaymentMethodType.xenditOvo.rawValue, name: "OVO")

    // `DefaultCheckoutScope` writes into `DIContainer.shared`, so this class resets it on both sides.
    // Without that, its scopes' async init races whichever class clears the container next, and the
    // failure surfaces in an unrelated test.
    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
        navigator = CheckoutNavigator(coordinator: CheckoutCoordinator())
        cardScope = MockPaymentMethodScope()
        qrScope = MockPaymentMethodScope()
        selection = MockSelectionScopeInternal()
        sut = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            navigator: navigator
        )
        sut.cachedPaymentMethodSelection = selection
        sut.availablePaymentMethods = [qrMethod, card]
        sut.paymentMethodScopeCache = [qrMethod.type: qrScope, card.type: cardScope]
    }

    override func tearDown() async throws {
        sut = nil
        navigator = nil
        cardScope = nil
        qrScope = nil
        selection = nil
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_retryPayment_withNothingAttempted_doesNothing() {
        sut.retryPayment()

        XCTAssertEqual(cardScope.submitCallCount, 0)
        XCTAssertFalse(selection.paidWithVaulted)
    }

    func test_retryPayment_afterACardPayment_resubmitsThatScope() {
        sut.updateNavigationState(.paymentMethod(TestData.PaymentMethodTypes.card))
        sut.startProcessing(payingWith: cardScope)

        sut.retryPayment()

        XCTAssertEqual(cardScope.submitCallCount, 1)
        XCTAssertFalse(selection.paidWithVaulted)
    }

    // The inline flow never leaves `.paymentMethodSelection`, because the merchant renders the card
    // form on their own screen. Reading the attempt off the navigation state would call the vault.
    func test_retryPayment_afterAnInlineCardPayment_resubmitsThatScope() {
        sut.updateNavigationState(.paymentMethodSelection)
        sut.startProcessing(payingWith: cardScope)

        sut.retryPayment()

        XCTAssertEqual(cardScope.submitCallCount, 1)
        XCTAssertFalse(selection.paidWithVaulted)
    }

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
    func test_retryPayment_afterCvvRecapture_paysWithTheSavedCardAgain() async {
        sut.updateNavigationState(.cvvRecapture)
        sut.startProcessing(payingWith: nil)

        sut.retryPayment()
        await Task.yield()

        XCTAssertTrue(selection.paidWithVaulted)
    }

    func test_retryPayment_afterSuccess_doesNothing() {
        sut.startProcessing(payingWith: cardScope)
        sut.updateNavigationState(.success(PaymentResult(paymentId: TestData.PaymentIds.success, status: .success)))

        sut.retryPayment()

        XCTAssertEqual(cardScope.submitCallCount, 0)
    }

    func test_retryPayment_afterFailure_stillTargetsTheFailedAttempt() {
        sut.startProcessing(payingWith: cardScope)
        sut.updateNavigationState(.failure(PrimerError.unknown(message: "declined")))

        sut.retryPayment()

        XCTAssertEqual(cardScope.submitCallCount, 1)
        XCTAssertEqual(cardScope.startCallCount, 0)
    }

    func test_retryPayment_afterChoosingAnotherMethod_doesNotResubmitTheEarlierOne() {
        sut.startProcessing(payingWith: cardScope)
        sut.handlePaymentError(PrimerError.unknown(message: "declined"))
        sut.cancelActivePaymentMethod(returnToSelection: true)

        sut.retryPayment()

        XCTAssertEqual(cardScope.submitCallCount, 0)
    }

    // Every way back to the list goes through navigation, not only the error screen's button.
    func test_retryPayment_afterBackingOutToTheList_doesNotResubmitTheEarlierOne() {
        sut.startProcessing(payingWith: cardScope)
        sut.updateNavigationState(.paymentMethodSelection, syncToNavigator: false)

        sut.retryPayment()

        XCTAssertEqual(cardScope.submitCallCount, 0)
    }

    // QR, ACH and Apple Pay never reach `startProcessing`, so a retry has to open them again.
    func test_retryPayment_afterAMethodThatNeverStartsProcessingFails_restartsIt() {
        sut.updateNavigationState(.paymentMethodSelection)
        sut.handlePaymentMethodSelection(qrMethod)
        sut.handlePaymentError(PrimerError.unknown(message: "declined"))

        sut.retryPayment()

        XCTAssertEqual(qrScope.prepareForReentryCallCount, 1)
        XCTAssertEqual(qrScope.startCallCount, 2)
        XCTAssertEqual(qrScope.submitCallCount, 0)
        XCTAssertEqual(sut.navigationState, .paymentMethod(qrMethod.type))
        // The failure screen is gone, so Back returns to the list rather than to the old error.
        let stack = navigator.checkoutCoordinator.navigationStack
        XCTAssertEqual(stack.count, 2)
        XCTAssertEqual(stack.first, .paymentMethodSelection)
    }

    func test_retryPayment_afterReturningToTheListAndFailingElsewhere_restartsTheNewMethod() {
        sut.handlePaymentMethodSelection(card)
        sut.startProcessing(payingWith: cardScope)
        sut.handlePaymentError(PrimerError.unknown(message: "declined"))
        sut.cancelActivePaymentMethod(returnToSelection: true)
        sut.handlePaymentMethodSelection(qrMethod)
        sut.handlePaymentError(PrimerError.unknown(message: "declined"))

        sut.retryPayment()

        XCTAssertEqual(cardScope.submitCallCount, 0)
        XCTAssertEqual(cardScope.startCallCount, 1)
        XCTAssertEqual(qrScope.startCallCount, 2)
    }

    // The merchant's onBeforePaymentCreate aborted, so there are no details to re-submit.
    func test_retryPayment_afterAFailureBeforeProcessing_reopensTheMethod() {
        sut.handlePaymentMethodSelection(card)
        sut.handlePaymentError(PrimerError.merchantError(message: "Payment creation aborted"))

        sut.retryPayment()

        XCTAssertEqual(sut.navigationState, .paymentMethod(card.type))
        XCTAssertEqual(cardScope.submitCallCount, 0)
    }

    // The error screen stays tappable until the navigation change reaches the view.
    func test_retryPayment_tappedTwice_restartsOnce() {
        sut.handlePaymentMethodSelection(qrMethod)
        sut.handlePaymentError(PrimerError.unknown(message: "declined"))

        sut.retryPayment()
        sut.retryPayment()

        XCTAssertEqual(qrScope.startCallCount, 2)
        XCTAssertEqual(qrScope.prepareForReentryCallCount, 1)
    }
}
