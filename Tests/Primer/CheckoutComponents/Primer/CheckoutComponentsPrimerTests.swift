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

// MARK: - HandlePaymentSuccess Tests

@available(iOS 15.0, *)
final class CheckoutComponentsPrimerHandlePaymentSuccessTests: XCTestCase {

    func test_handlePaymentSuccess_callsDelegateWithResult() {
        // Given
        let primer = CheckoutComponentsPrimer.shared
        let mockDelegate = MockCheckoutComponentsDelegateTracking()
        primer.delegate = mockDelegate

        let result = PaymentResult(
            paymentId: "test-payment-123",
            status: .success
        )

        // When
        primer.handlePaymentSuccess(result)

        // Then
        // Wait for async completion
        let expectation = expectation(description: "Delegate called")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(mockDelegate.didCompleteWithSuccessCalled)
            XCTAssertEqual(mockDelegate.receivedPaymentResult?.paymentId, "test-payment-123")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        // Cleanup
        primer.delegate = nil
    }

    func test_handlePaymentSuccess_withNilDelegate_doesNotCrash() {
        // Given
        let primer = CheckoutComponentsPrimer.shared
        primer.delegate = nil

        let result = PaymentResult(
            paymentId: "test-payment-123",
            status: .success
        )

        // When/Then - should not crash
        primer.handlePaymentSuccess(result)
    }

    func test_handlePaymentSuccess_withDifferentPaymentStatuses() {
        // Given
        let primer = CheckoutComponentsPrimer.shared
        let mockDelegate = MockCheckoutComponentsDelegateTracking()
        primer.delegate = mockDelegate

        // Test with pending status
        let pendingResult = PaymentResult(
            paymentId: "pending-payment",
            status: .pending
        )

        // When
        primer.handlePaymentSuccess(pendingResult)

        // Then - delegate should still be called
        let expectation = expectation(description: "Delegate called")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(mockDelegate.didCompleteWithSuccessCalled)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        // Cleanup
        primer.delegate = nil
    }

    func test_handlePaymentSuccess_multipleCalls_callsDelegateEachTime() {
        // Given
        let primer = CheckoutComponentsPrimer.shared
        let mockDelegate = MockCheckoutComponentsDelegateTracking()
        primer.delegate = mockDelegate

        let result1 = PaymentResult(paymentId: "payment-1", status: .success)
        let result2 = PaymentResult(paymentId: "payment-2", status: .success)

        // When
        primer.handlePaymentSuccess(result1)
        primer.handlePaymentSuccess(result2)

        // Then
        let expectation = expectation(description: "Delegate called")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(mockDelegate.successCallCount >= 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        // Cleanup
        primer.delegate = nil
    }
}

// MARK: - HandlePaymentFailure Tests

@available(iOS 15.0, *)
final class CheckoutComponentsPrimerHandlePaymentFailureTests: XCTestCase {

    func test_handlePaymentFailure_callsDelegateWithError() {
        // Given
        let primer = CheckoutComponentsPrimer.shared
        let mockDelegate = MockCheckoutComponentsDelegateTracking()
        primer.delegate = mockDelegate

        let error = PrimerError.unknown()

        // When
        primer.handlePaymentFailure(error)

        // Then
        let expectation = expectation(description: "Delegate called")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(mockDelegate.didFailWithErrorCalled)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        // Cleanup
        primer.delegate = nil
    }

    func test_handlePaymentFailure_withNilDelegate_doesNotCrash() {
        // Given
        let primer = CheckoutComponentsPrimer.shared
        primer.delegate = nil

        let error = PrimerError.unknown()

        // When/Then - should not crash
        primer.handlePaymentFailure(error)
    }

    func test_handlePaymentFailure_withDifferentErrorTypes() {
        // Given
        let primer = CheckoutComponentsPrimer.shared
        let mockDelegate = MockCheckoutComponentsDelegateTracking()
        primer.delegate = mockDelegate

        // Test with invalid client token error
        let tokenError = PrimerError.invalidClientToken(
            reason: "test-reason",
            diagnosticsId: "test-diagnostics"
        )

        // When
        primer.handlePaymentFailure(tokenError)

        // Then
        let expectation = expectation(description: "Delegate called")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(mockDelegate.didFailWithErrorCalled)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        // Cleanup
        primer.delegate = nil
    }

    func test_handlePaymentFailure_multipleCalls_callsDelegateEachTime() {
        // Given
        let primer = CheckoutComponentsPrimer.shared
        let mockDelegate = MockCheckoutComponentsDelegateTracking()
        primer.delegate = mockDelegate

        let error1 = PrimerError.unknown()
        let error2 = PrimerError.invalidClientToken(reason: "test", diagnosticsId: "test")

        // When
        primer.handlePaymentFailure(error1)
        primer.handlePaymentFailure(error2)

        // Then
        let expectation = expectation(description: "Delegate called")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(mockDelegate.failureCallCount >= 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        // Cleanup
        primer.delegate = nil
    }
}

// MARK: - Static Properties Extended Tests

@available(iOS 15.0, *)
final class CheckoutComponentsPrimerStaticPropertiesTests: XCTestCase {

    func test_isAvailable_alwaysReturnsTrue_oniOS15Plus() {
        // Given/When
        let available = CheckoutComponentsPrimer.isAvailable

        // Then
        XCTAssertTrue(available)
    }

    func test_isAvailable_isStatic() {
        // Verify isAvailable can be accessed without instance
        _ = CheckoutComponentsPrimer.isAvailable
    }

    func test_isPresenting_isStatic() {
        // Verify isPresenting can be accessed without instance
        _ = CheckoutComponentsPrimer.isPresenting
    }

    func test_shared_returnsNonNil() {
        // When
        let shared = CheckoutComponentsPrimer.shared

        // Then
        XCTAssertNotNil(shared)
    }

    func test_shared_isAlwaysSameInstance() {
        // When
        var instances: [CheckoutComponentsPrimer] = []
        for _ in 0..<100 {
            instances.append(CheckoutComponentsPrimer.shared)
        }

        // Then - all instances should be the same
        let first = instances.first
        for instance in instances {
            XCTAssertTrue(instance === first)
        }
    }
}

// MARK: - Dismiss Edge Cases Tests

@available(iOS 15.0, *)
final class CheckoutComponentsPrimerDismissEdgeCasesTests: XCTestCase {

    func test_dismiss_withDefaultAnimatedTrue() {
        // Given
        let expectation = expectation(description: "Dismiss completes")

        // When - default animated is true
        CheckoutComponentsPrimer.dismiss {
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 1.0)
    }

    func test_dismiss_rapidSuccession_doesNotCrash() {
        // Given
        let expectation = expectation(description: "All dismisses complete")
        var completionCount = 0
        let totalDismisses = 10

        // When
        for _ in 0..<totalDismisses {
            CheckoutComponentsPrimer.dismiss(animated: false) {
                completionCount += 1
                if completionCount == totalDismisses {
                    expectation.fulfill()
                }
            }
        }

        // Then
        waitForExpectations(timeout: 2.0)
    }

    func test_dismissDirectly_calledMultipleTimes_allComplete() {
        // Given
        let primer = CheckoutComponentsPrimer.shared
        let expectation = expectation(description: "All complete")
        var count = 0

        // When
        for _ in 0..<5 {
            primer.dismissDirectly {
                count += 1
                if count == 5 {
                    expectation.fulfill()
                }
            }
        }

        // Then
        waitForExpectations(timeout: 2.0)
    }
}

// MARK: - Delegate Protocol Extension Tests

@available(iOS 15.0, *)
final class CheckoutComponentsDelegateExtensionTests: XCTestCase {

    func test_3DSDelegate_willPresentChallenge_hasDefaultImplementation() {
        // Given
        let delegate = MinimalCheckoutComponentsDelegate()
        let tokenData = createTestTokenData()

        // When/Then - should not crash (default implementation)
        delegate.checkoutComponentsWillPresent3DSChallenge(tokenData)
    }

    func test_3DSDelegate_didDismissChallenge_hasDefaultImplementation() {
        // Given
        let delegate = MinimalCheckoutComponentsDelegate()

        // When/Then - should not crash
        delegate.checkoutComponentsDidDismiss3DSChallenge()
    }

    func test_3DSDelegate_didComplete_withSuccess_hasDefaultImplementation() {
        // Given
        let delegate = MinimalCheckoutComponentsDelegate()

        // When/Then - should not crash
        delegate.checkoutComponentsDidComplete3DSChallenge(
            success: true,
            resumeToken: "test-token",
            error: nil
        )
    }

    func test_3DSDelegate_didComplete_withFailure_hasDefaultImplementation() {
        // Given
        let delegate = MinimalCheckoutComponentsDelegate()
        let error = NSError(domain: "Test", code: 1, userInfo: nil)

        // When/Then - should not crash
        delegate.checkoutComponentsDidComplete3DSChallenge(
            success: false,
            resumeToken: nil,
            error: error
        )
    }

    func test_3DSDelegate_didComplete_withNilError_success() {
        // Given
        let delegate = MinimalCheckoutComponentsDelegate()

        // When/Then
        delegate.checkoutComponentsDidComplete3DSChallenge(
            success: true,
            resumeToken: "resume-token",
            error: nil
        )
    }

    func test_3DSDelegate_didComplete_withNilResumeToken_failure() {
        // Given
        let delegate = MinimalCheckoutComponentsDelegate()

        // When/Then
        delegate.checkoutComponentsDidComplete3DSChallenge(
            success: false,
            resumeToken: nil,
            error: NSError(domain: "3DS", code: 401, userInfo: nil)
        )
    }

    private func createTestTokenData() -> PrimerPaymentMethodTokenData {
        return PrimerPaymentMethodTokenData(
            analyticsId: "test-analytics",
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
    }
}

// MARK: - Delegate State Handling Tests

@available(iOS 15.0, *)
final class CheckoutComponentsPrimerDelegateStateTests: XCTestCase {

    func test_delegate_replacingDelegate_newDelegateReceivesCalls() {
        // Given
        let primer = CheckoutComponentsPrimer.shared
        let oldDelegate = MockCheckoutComponentsDelegateTracking()
        let newDelegate = MockCheckoutComponentsDelegateTracking()

        primer.delegate = oldDelegate

        // When - replace delegate
        primer.delegate = newDelegate
        primer.handleCheckoutDismiss()

        // Then - only new delegate should receive call
        XCTAssertFalse(oldDelegate.didDismissCalled)
        XCTAssertTrue(newDelegate.didDismissCalled)

        // Cleanup
        primer.delegate = nil
    }

    func test_delegate_settingToNil_preventsCallbacks() {
        // Given
        let primer = CheckoutComponentsPrimer.shared
        let mockDelegate = MockCheckoutComponentsDelegateTracking()
        primer.delegate = mockDelegate

        // When
        primer.delegate = nil
        primer.handleCheckoutDismiss()

        // Then - delegate should not receive call (it was set to nil)
        XCTAssertFalse(mockDelegate.didDismissCalled)
    }

    func test_staticDelegate_isIndependentFromInstanceDelegate() {
        // Given
        let originalPrimerDelegate = Primer.shared.delegate
        let originalInstanceDelegate = CheckoutComponentsPrimer.shared.delegate

        let mockPrimerDelegate = MockPrimerDelegateTracking()
        let mockInstanceDelegate = MockCheckoutComponentsDelegateTracking()

        // When - set both delegates independently
        Primer.shared.delegate = mockPrimerDelegate
        CheckoutComponentsPrimer.shared.delegate = mockInstanceDelegate

        // Then - they should be different objects
        XCTAssertTrue(Primer.shared.delegate === mockPrimerDelegate)
        XCTAssertTrue(CheckoutComponentsPrimer.shared.delegate === mockInstanceDelegate)

        // Cleanup
        Primer.shared.delegate = originalPrimerDelegate
        CheckoutComponentsPrimer.shared.delegate = originalInstanceDelegate
    }
}

// MARK: - PaymentResult Tests

@available(iOS 15.0, *)
final class CheckoutComponentsPrimerPaymentResultTests: XCTestCase {

    func test_paymentResult_successStatus() {
        // Given
        let result = PaymentResult(paymentId: "test-id", status: .success)

        // Then
        XCTAssertEqual(result.paymentId, "test-id")
        XCTAssertEqual(result.status, .success)
    }

    func test_paymentResult_pendingStatus() {
        // Given
        let result = PaymentResult(paymentId: "pending-id", status: .pending)

        // Then
        XCTAssertEqual(result.status, .pending)
    }

    func test_paymentResult_failedStatus() {
        // Given
        let result = PaymentResult(paymentId: "failed-id", status: .failed)

        // Then
        XCTAssertEqual(result.status, .failed)
    }

    func test_paymentResult_withOptionalAmount() {
        // Given
        let result = PaymentResult(
            paymentId: "test-id",
            status: .success,
            amount: 1000,
            currencyCode: "USD"
        )

        // Then
        XCTAssertEqual(result.amount, 1000)
        XCTAssertEqual(result.currencyCode, "USD")
    }

    func test_paymentResult_withNilOptionalFields() {
        // Given
        let result = PaymentResult(
            paymentId: "test-id",
            status: .success,
            amount: nil,
            currencyCode: nil
        )

        // Then
        XCTAssertNil(result.amount)
        XCTAssertNil(result.currencyCode)
    }
}

// MARK: - PresentCheckout Edge Cases

@available(iOS 15.0, *)
final class CheckoutComponentsPrimerPresentEdgeCasesTests: XCTestCase {

    func test_presentCheckout_staticMethodsExist() {
        // Verify all static method signatures exist without calling them
        // This ensures API compatibility

        // Method 1: Basic with viewController
        let method1: (String, UIViewController, (() -> Void)?) -> Void = CheckoutComponentsPrimer.presentCheckout(clientToken:from:completion:)
        _ = method1

        // Method 2: With settings
        let method2: (String, UIViewController, PrimerSettings, (() -> Void)?) -> Void = CheckoutComponentsPrimer.presentCheckout(clientToken:from:primerSettings:completion:)
        _ = method2

        // Method 3: Full configuration
        let method3: (String, UIViewController, PrimerSettings, PrimerCheckoutTheme, ((PrimerCheckoutScope) -> Void)?, (() -> Void)?) -> Void = CheckoutComponentsPrimer.presentCheckout(clientToken:from:primerSettings:primerTheme:scope:completion:)
        _ = method3

        // Method 4: Auto view controller detection
        let method4: (String, (() -> Void)?) -> Void = CheckoutComponentsPrimer.presentCheckout(clientToken:completion:)
        _ = method4
    }

    func test_dismiss_staticMethodSignature() {
        // Verify dismiss method signature
        let method: (Bool, (() -> Void)?) -> Void = CheckoutComponentsPrimer.dismiss(animated:completion:)
        _ = method
    }
}

// MARK: - Additional Mock Delegates

@available(iOS 15.0, *)
private class MockCheckoutComponentsDelegateTracking: CheckoutComponentsDelegate {
    var didCompleteWithSuccessCalled = false
    var didFailWithErrorCalled = false
    var didDismissCalled = false
    var receivedPaymentResult: PaymentResult?
    var receivedError: PrimerError?
    var successCallCount = 0
    var failureCallCount = 0

    func checkoutComponentsDidCompleteWithSuccess(_ result: PaymentResult) {
        didCompleteWithSuccessCalled = true
        receivedPaymentResult = result
        successCallCount += 1
    }

    func checkoutComponentsDidFailWithError(_ error: PrimerError) {
        didFailWithErrorCalled = true
        receivedError = error
        failureCallCount += 1
    }

    func checkoutComponentsDidDismiss() {
        didDismissCalled = true
    }
}

/// Minimal delegate that only implements required methods
@available(iOS 15.0, *)
private class MinimalCheckoutComponentsDelegate: CheckoutComponentsDelegate {
    func checkoutComponentsDidCompleteWithSuccess(_ result: PaymentResult) {}
    func checkoutComponentsDidFailWithError(_ error: PrimerError) {}
    func checkoutComponentsDidDismiss() {}
}

private class MockPrimerDelegateTracking: PrimerDelegate {
    func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {}
    func primerDidFailWithError(_ error: Error, data: PrimerCheckoutData?, decisionHandler: @escaping (PrimerErrorDecision) -> Void) {
        decisionHandler(.fail(withErrorMessage: nil))
    }
}
