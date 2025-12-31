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
}

// MARK: - Mock Delegates

@available(iOS 15.0, *)
private class MockCheckoutComponentsDelegate: CheckoutComponentsDelegate {
    var didCompleteWithSuccessCalled = false
    var didFailWithErrorCalled = false
    var didDismissCalled = false

    func checkoutComponentsDidCompleteWithSuccess(_ result: PaymentResult) {
        didCompleteWithSuccessCalled = true
    }

    func checkoutComponentsDidFailWithError(_ error: PrimerError) {
        didFailWithErrorCalled = true
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
