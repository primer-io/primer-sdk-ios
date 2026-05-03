//
//  PrimerCheckoutPresenterTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
@MainActor
final class PrimerCheckoutPresenterTests: XCTestCase {

    private var sut: PrimerCheckoutPresenter!
    private var mockDelegate: MockPrimerCheckoutPresenterDelegate!

    override func setUp() {
        super.setUp()
        sut = PrimerCheckoutPresenter.shared
        mockDelegate = MockPrimerCheckoutPresenterDelegate()
        sut.delegate = mockDelegate
    }

    override func tearDown() {
        sut.delegate = nil
        mockDelegate = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Singleton

    func test_shared_returnsSameInstance() {
        // Given
        let first = PrimerCheckoutPresenter.shared

        // When
        let second = PrimerCheckoutPresenter.shared

        // Then
        XCTAssertTrue(first === second)
    }

    // MARK: - isAvailable

    func test_isAvailable_returnsTrue() {
        // Given / When
        let available = PrimerCheckoutPresenter.isAvailable

        // Then
        XCTAssertTrue(available)
    }

    // MARK: - isPresenting

    func test_isPresenting_initiallyFalse() {
        // Given / When
        let presenting = PrimerCheckoutPresenter.isPresenting

        // Then
        XCTAssertFalse(presenting)
    }

    // MARK: - handlePaymentSuccess

    func test_handlePaymentSuccess_withDelegate_callsDidCompleteWithSuccess() {
        // Given
        let result = PaymentResult(paymentId: TestData.PaymentIds.success, status: .success)

        // When
        sut.handlePaymentSuccess(result)

        // Then - dismissDirectly calls completion immediately when no active controller
        XCTAssertEqual(mockDelegate.didCompleteWithSuccessCallCount, 1)
        XCTAssertEqual(mockDelegate.capturedSuccessResult?.paymentId, TestData.PaymentIds.success)
        XCTAssertEqual(mockDelegate.capturedSuccessResult?.status, .success)
    }

    func test_handlePaymentSuccess_withoutDelegate_doesNotCrash() {
        // Given
        sut.delegate = nil
        let result = PaymentResult(paymentId: TestData.PaymentIds.success, status: .success)

        // When / Then - should not crash
        sut.handlePaymentSuccess(result)
    }

    // MARK: - handlePaymentFailure

    func test_handlePaymentFailure_withDelegate_callsDidFailWithError() {
        // Given
        let error = PrimerError.invalidValue(
            key: TestData.ErrorKeys.test,
            value: nil,
            reason: nil,
            diagnosticsId: TestData.DiagnosticsIds.test
        )

        // When
        sut.handlePaymentFailure(error)

        // Then
        XCTAssertEqual(mockDelegate.didFailWithErrorCallCount, 1)
        XCTAssertNotNil(mockDelegate.capturedError)
    }

    func test_handlePaymentFailure_withoutDelegate_doesNotCrash() {
        // Given
        sut.delegate = nil
        let error = PrimerError.invalidValue(
            key: TestData.ErrorKeys.test,
            value: nil,
            reason: nil,
            diagnosticsId: TestData.DiagnosticsIds.test
        )

        // When / Then - should not crash
        sut.handlePaymentFailure(error)
    }

    // MARK: - handleCheckoutDismiss

    func test_handleCheckoutDismiss_withDelegate_callsDidDismiss() {
        // Given / When
        sut.handleCheckoutDismiss()

        // Then
        XCTAssertEqual(mockDelegate.didDismissCallCount, 1)
    }

    func test_handleCheckoutDismiss_withoutDelegate_doesNotCrash() {
        // Given
        sut.delegate = nil

        // When / Then - should not crash
        sut.handleCheckoutDismiss()
    }

    // MARK: - dismiss

    func test_dismiss_withNoActiveController_callsCompletionImmediately() {
        // Given
        let expectation = expectation(description: "Completion called")

        // When
        PrimerCheckoutPresenter.dismiss(animated: true) {
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    func test_dismiss_withNoActiveController_doesNotCallDelegate() {
        // Given
        let expectation = expectation(description: "Completion called")

        // When
        PrimerCheckoutPresenter.dismiss(animated: false) {
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockDelegate.didDismissCallCount, 0)
    }

    // MARK: - dismissDirectly

    func test_dismissDirectly_withNoController_callsCompletionImmediately() {
        // Given
        let expectation = expectation(description: "Completion called")

        // When
        sut.dismissDirectly {
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - dismissCheckout

    func test_dismissCheckout_withNoController_completesWithoutCrash() {
        // Given / When / Then - should not crash
        sut.dismissCheckout()
    }
}
