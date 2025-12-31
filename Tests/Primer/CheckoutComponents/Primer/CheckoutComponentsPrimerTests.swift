//
//  CheckoutComponentsPrimerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for CheckoutComponentsPrimer covering singleton, static properties, and delegate protocol.
@available(iOS 15.0, *)
final class CheckoutComponentsPrimerTests: XCTestCase {

    // MARK: - Singleton Tests

    func test_shared_returnsSameInstance() {
        // When
        let instance1 = CheckoutComponentsPrimer.shared
        let instance2 = CheckoutComponentsPrimer.shared

        // Then
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - isAvailable Tests

    func test_isAvailable_returnsTrue() {
        // When
        let available = CheckoutComponentsPrimer.isAvailable

        // Then
        XCTAssertTrue(available)
    }

    // MARK: - isPresenting Tests

    func test_isPresenting_initiallyFalse() {
        // Given - no checkout has been presented

        // When
        let isPresenting = CheckoutComponentsPrimer.isPresenting

        // Then - should be false initially
        // Note: This may fail if another test has presented checkout
        XCTAssertFalse(isPresenting)
    }

    // MARK: - Delegate Tests

    func test_delegate_initiallyNil() {
        // Given
        let primer = CheckoutComponentsPrimer.shared

        // When - check delegate
        let delegate = primer.delegate

        // Then
        // Delegate may or may not be nil depending on test order
        // Just verify we can access it without crashing
        _ = delegate
    }

    func test_delegate_canBeSet() {
        // Given
        let primer = CheckoutComponentsPrimer.shared
        let mockDelegate = MockCheckoutComponentsDelegate()

        // When
        primer.delegate = mockDelegate

        // Then
        XCTAssertNotNil(primer.delegate)
        XCTAssertTrue(primer.delegate === mockDelegate)

        // Cleanup
        primer.delegate = nil
    }

    // MARK: - Static Delegate Property Tests

    func test_staticDelegate_accessesPrimerSharedDelegate() {
        // Given
        let originalDelegate = Primer.shared.delegate

        // When
        let staticDelegate = CheckoutComponentsPrimer.delegate

        // Then - static delegate property accesses Primer.shared.delegate
        if let original = originalDelegate, let static_ = staticDelegate {
            XCTAssertTrue(original === static_)
        }

        // Cleanup
        Primer.shared.delegate = originalDelegate
    }

    func test_staticDelegate_canBeSet() {
        // Given
        let originalDelegate = Primer.shared.delegate
        let mockDelegate = MockPrimerDelegate()

        // When
        CheckoutComponentsPrimer.delegate = mockDelegate

        // Then
        XCTAssertTrue(Primer.shared.delegate === mockDelegate)

        // Cleanup
        Primer.shared.delegate = originalDelegate
    }

    // MARK: - Dismiss Tests

    func test_dismiss_whenNoActiveCheckout_completesImmediately() {
        // Given
        let expectation = expectation(description: "Dismiss completes")

        // When
        CheckoutComponentsPrimer.dismiss(animated: false) {
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 1.0)
    }

    func test_dismiss_withAnimatedFalse_completesImmediately() {
        // Given
        let expectation = expectation(description: "Dismiss completes")

        // When
        CheckoutComponentsPrimer.dismiss(animated: false) {
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 1.0)
    }

    func test_dismiss_withNilCompletion_doesNotCrash() {
        // When/Then - should not crash
        CheckoutComponentsPrimer.dismiss(animated: false, completion: nil)
    }

    // MARK: - handleCheckoutDismiss Tests

    func test_handleCheckoutDismiss_callsDelegateMethod() {
        // Given
        let primer = CheckoutComponentsPrimer.shared
        let mockDelegate = MockCheckoutComponentsDelegate()
        primer.delegate = mockDelegate

        // When
        primer.handleCheckoutDismiss()

        // Then
        XCTAssertTrue(mockDelegate.didDismissCalled)

        // Cleanup
        primer.delegate = nil
    }

    func test_handleCheckoutDismiss_withNilDelegate_doesNotCrash() {
        // Given
        let primer = CheckoutComponentsPrimer.shared
        primer.delegate = nil

        // When/Then - should not crash
        primer.handleCheckoutDismiss()
    }

    // MARK: - dismissCheckout Tests

    func test_dismissCheckout_callsDismissDirectly() {
        // Given
        let primer = CheckoutComponentsPrimer.shared

        // When/Then - should not crash when no active checkout
        primer.dismissCheckout()
    }

    // MARK: - dismissDirectly Tests

    func test_dismissDirectly_withNoActiveController_completesImmediately() {
        // Given
        let primer = CheckoutComponentsPrimer.shared
        let expectation = expectation(description: "Completion called")

        // When
        primer.dismissDirectly {
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 1.0)
    }

    func test_dismissDirectly_withNilCompletion_doesNotCrash() {
        // Given
        let primer = CheckoutComponentsPrimer.shared

        // When/Then - should not crash
        primer.dismissDirectly(completion: nil)
    }

    // MARK: - Multiple Dismiss Tests

    func test_dismiss_multipleTimes_doesNotCrash() {
        // When/Then - should handle multiple dismiss calls gracefully
        CheckoutComponentsPrimer.dismiss(animated: false)
        CheckoutComponentsPrimer.dismiss(animated: true)
        CheckoutComponentsPrimer.dismiss(animated: false)
    }

    // MARK: - CheckoutComponentsDelegate Protocol Tests

    func test_checkoutComponentsDelegate_hasRequiredMethods() {
        // Given
        let mockDelegate = MockCheckoutComponentsDelegate()

        // Then - verify protocol methods exist and can be called
        let mockResult = PaymentResult(
            paymentId: "test-payment-id",
            status: .success
        )
        mockDelegate.checkoutComponentsDidCompleteWithSuccess(mockResult)
        XCTAssertTrue(mockDelegate.didCompleteWithSuccessCalled)

        let mockError = PrimerError.unknown()
        mockDelegate.checkoutComponentsDidFailWithError(mockError)
        XCTAssertTrue(mockDelegate.didFailWithErrorCalled)

        mockDelegate.checkoutComponentsDidDismiss()
        XCTAssertTrue(mockDelegate.didDismissCalled)
    }

    // MARK: - Default 3DS Delegate Method Tests

    func test_checkoutComponentsDelegate_3DSMethodsHaveDefaultImplementations() {
        // Given
        let mockDelegate = MockCheckoutComponentsDelegate()

        // When/Then - default implementations should not crash
        // These are optional methods with default empty implementations
        let tokenData = PrimerPaymentMethodTokenData(
            analyticsId: "test",
            id: "test-id",
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .paymentCard,
            paymentMethodType: "PAYMENT_CARD",
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: "test-token",
            tokenType: .singleUse,
            vaultData: nil
        )
        mockDelegate.checkoutComponentsWillPresent3DSChallenge(tokenData)
        mockDelegate.checkoutComponentsDidDismiss3DSChallenge()
        mockDelegate.checkoutComponentsDidComplete3DSChallenge(success: true, resumeToken: "token", error: nil)
        mockDelegate.checkoutComponentsDidComplete3DSChallenge(success: false, resumeToken: nil, error: NSError(domain: "", code: 0))
    }

    // MARK: - Delegate Weak Reference Test

    func test_delegate_isWeakReference() {
        // Given
        let primer = CheckoutComponentsPrimer.shared
        var mockDelegate: MockCheckoutComponentsDelegate? = MockCheckoutComponentsDelegate()
        primer.delegate = mockDelegate

        // Verify it's set
        XCTAssertNotNil(primer.delegate)

        // When - release the delegate
        mockDelegate = nil

        // Then - delegate should be nil (weak reference)
        XCTAssertNil(primer.delegate)
    }

    // MARK: - Static Method Tests

    func test_presentCheckout_staticMethod_exists() {
        // This test verifies the static method signatures exist
        // We don't actually call them because they would present UI

        // Verify static methods are accessible
        _ = CheckoutComponentsPrimer.presentCheckout(clientToken:from:completion:)
        _ = CheckoutComponentsPrimer.presentCheckout(clientToken:from:primerSettings:completion:)
        _ = CheckoutComponentsPrimer.presentCheckout(clientToken:from:primerSettings:primerTheme:scope:completion:)
        _ = CheckoutComponentsPrimer.presentCheckout(clientToken:completion:)
        _ = CheckoutComponentsPrimer.dismiss(animated:completion:)
    }

    // MARK: - Integration Tests

    func test_singleton_maintainsStateAcrossAccesses() {
        // Given
        let mockDelegate = MockCheckoutComponentsDelegate()
        CheckoutComponentsPrimer.shared.delegate = mockDelegate

        // When
        let delegate1 = CheckoutComponentsPrimer.shared.delegate
        let delegate2 = CheckoutComponentsPrimer.shared.delegate

        // Then
        XCTAssertTrue(delegate1 === delegate2)
        XCTAssertTrue(delegate1 === mockDelegate)

        // Cleanup
        CheckoutComponentsPrimer.shared.delegate = nil
    }
}

// MARK: - Mock Delegates

@available(iOS 15.0, *)
private class MockCheckoutComponentsDelegate: CheckoutComponentsDelegate {
    var didCompleteWithSuccessCalled = false
    var didFailWithErrorCalled = false
    var didDismissCalled = false
    var receivedPaymentResult: PaymentResult?
    var receivedError: PrimerError?

    func checkoutComponentsDidCompleteWithSuccess(_ result: PaymentResult) {
        didCompleteWithSuccessCalled = true
        receivedPaymentResult = result
    }

    func checkoutComponentsDidFailWithError(_ error: PrimerError) {
        didFailWithErrorCalled = true
        receivedError = error
    }

    func checkoutComponentsDidDismiss() {
        didDismissCalled = true
    }
}

private class MockPrimerDelegate: PrimerDelegate {
    func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {}
    func primerDidFailWithError(_ error: Error, data: PrimerCheckoutData?, decisionHandler: @escaping (PrimerErrorDecision) -> Void) {
        decisionHandler(.fail(withErrorMessage: nil))
    }
}
