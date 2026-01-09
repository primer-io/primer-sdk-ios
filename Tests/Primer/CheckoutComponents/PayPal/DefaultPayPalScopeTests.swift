//
//  DefaultPayPalScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import XCTest
@testable import PrimerSDK

/// Tests for DefaultPayPalScope.
@available(iOS 15.0, *)
final class DefaultPayPalScopeTests: XCTestCase {

    private var mockCheckoutScope: DefaultCheckoutScope!
    private var mockInteractor: MockProcessPayPalInteractor!
    private var sut: DefaultPayPalScope!

    @MainActor
    override func setUp() {
        super.setUp()
        mockCheckoutScope = createCheckoutScope()
        mockInteractor = MockProcessPayPalInteractor()
    }

    @MainActor
    override func tearDown() {
        sut = nil
        mockInteractor = nil
        mockCheckoutScope = nil
        super.tearDown()
    }

    // MARK: - Mock Types

    private final class MockProcessPayPalInteractor: ProcessPayPalPaymentInteractor {
        var executeResult: Result<PaymentResult, Error> = .success(
            PaymentResult(paymentId: "mock-payment", status: .success)
        )
        var executeCalled = false

        func execute() async throws -> PaymentResult {
            executeCalled = true
            return try executeResult.get()
        }
    }

    // MARK: - Initialization Tests

    @MainActor
    func test_init_setsDefaultPresentationContext() {
        // When
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )

        // Then
        XCTAssertEqual(sut.presentationContext, .fromPaymentSelection)
    }

    @MainActor
    func test_init_withDirectContext_setsPresentationContext() {
        // When
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            presentationContext: .direct,
            processPayPalInteractor: mockInteractor
        )

        // Then
        XCTAssertEqual(sut.presentationContext, .direct)
    }

    @MainActor
    func test_init_customizationPropertiesAreNil() {
        // When
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )

        // Then
        XCTAssertNil(sut.screen)
        XCTAssertNil(sut.payButton)
        XCTAssertNil(sut.submitButtonText)
    }

    // MARK: - Start Tests

    @MainActor
    func test_start_setsStateToIdle() async {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )

        // When
        sut.start()

        // Then - verify initial state through stream
        var receivedState: PayPalState?
        let expectation = expectation(description: "Receive state")

        Task {
            for await state in sut.state {
                receivedState = state
                expectation.fulfill()
                break
            }
        }

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedState?.status, .idle)
    }

    // MARK: - Submit Tests

    @MainActor
    func test_submit_callsInteractorExecute() async {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )

        // When
        sut.submit()

        // Allow async work to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Then
        XCTAssertTrue(mockInteractor.executeCalled)
    }

    @MainActor
    func test_submit_onSuccess_transitionsStateToSuccess() async {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )
        mockInteractor.executeResult = .success(PaymentResult(paymentId: "success-id", status: .success))

        var receivedStates: [PayPalState.Status] = []
        let expectation = expectation(description: "Receive success state")
        expectation.assertForOverFulfill = false

        // Track state changes
        let stateTask = Task { @MainActor in
            for await state in sut.state {
                receivedStates.append(state.status)
                if case .success = state.status {
                    expectation.fulfill()
                }
            }
        }

        // When
        sut.submit()

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        stateTask.cancel()

        XCTAssertTrue(receivedStates.contains(.success))
    }

    @MainActor
    func test_submit_onFailure_transitionsStateToFailure() async {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )
        mockInteractor.executeResult = .failure(NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"]))

        var receivedStates: [PayPalState.Status] = []
        let expectation = expectation(description: "Receive failure state")
        expectation.assertForOverFulfill = false

        // Track state changes
        let stateTask = Task { @MainActor in
            for await state in sut.state {
                receivedStates.append(state.status)
                if case .failure = state.status {
                    expectation.fulfill()
                }
            }
        }

        // When
        sut.submit()

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        stateTask.cancel()

        let failureState = receivedStates.first {
            if case .failure = $0 { return true }
            return false
        }
        XCTAssertNotNil(failureState)
    }

    // MARK: - Cancel Tests

    @MainActor
    func test_cancel_doesNotCrash() {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )

        // When/Then - verify cancel doesn't throw
        sut.cancel()
    }

    // MARK: - Navigation Tests

    @MainActor
    func test_onBack_withFromPaymentSelection_doesNotCrash() {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            presentationContext: .fromPaymentSelection,
            processPayPalInteractor: mockInteractor
        )

        // When/Then - verify onBack doesn't throw
        sut.onBack()
    }

    @MainActor
    func test_onBack_withDirectContext_doesNotCrash() {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            presentationContext: .direct,
            processPayPalInteractor: mockInteractor
        )

        // When/Then - verify onBack doesn't throw
        sut.onBack()
    }

    @MainActor
    func test_onCancel_doesNotCrash() {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )

        // When/Then - verify onCancel doesn't throw
        sut.onCancel()
    }

    // MARK: - Dismissal Mechanism Tests

    @MainActor
    func test_dismissalMechanism_returnsCheckoutScopeDismissalMechanism() {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )

        // Then - dismissal mechanism should match checkout scope
        XCTAssertEqual(sut.dismissalMechanism, mockCheckoutScope.dismissalMechanism)
    }

    // MARK: - UI Customization Tests

    @MainActor
    func test_screen_canBeSet() {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )

        // When
        sut.screen = { _ in EmptyView() }

        // Then
        XCTAssertNotNil(sut.screen)
    }

    @MainActor
    func test_payButton_canBeSet() {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )

        // When
        sut.payButton = { _ in EmptyView() }

        // Then
        XCTAssertNotNil(sut.payButton)
    }

    @MainActor
    func test_submitButtonText_canBeSet() {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )

        // When
        sut.submitButtonText = "Custom PayPal Button"

        // Then
        XCTAssertEqual(sut.submitButtonText, "Custom PayPal Button")
    }

    // MARK: - State Stream Tests

    @MainActor
    func test_state_returnsAsyncStream() async {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )

        // When
        sut.start()

        var receivedState: PayPalState?
        let expectation = expectation(description: "Receive initial state")

        Task {
            for await state in sut.state {
                receivedState = state
                expectation.fulfill()
                break
            }
        }

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedState)
    }

    @MainActor
    func test_state_emitsRedirectingDuringSubmit() async {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )

        var receivedStates: [PayPalState.Status] = []
        let redirectingExpectation = expectation(description: "Receive redirecting state")
        redirectingExpectation.assertForOverFulfill = false

        // Start tracking state changes BEFORE submit
        let stateTask = Task { @MainActor in
            for await state in sut.state {
                receivedStates.append(state.status)
                if case .redirecting = state.status {
                    redirectingExpectation.fulfill()
                }
            }
        }

        // Give the state subscription time to establish
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        // When
        sut.submit()

        // Then
        await fulfillment(of: [redirectingExpectation], timeout: 2.0)
        stateTask.cancel()

        XCTAssertTrue(receivedStates.contains(.redirecting))
    }

    // MARK: - PayPalState Tests

    @MainActor
    func test_PayPalState_defaultInitialization() {
        // When
        let state = PayPalState()

        // Then
        XCTAssertEqual(state.status, .idle)
        XCTAssertNil(state.paymentMethod)
        XCTAssertNil(state.surchargeAmount)
    }

    @MainActor
    func test_PayPalState_customInitialization() {
        // When
        let state = PayPalState(
            status: .loading,
            surchargeAmount: "+ $1.50"
        )

        // Then
        XCTAssertEqual(state.status, .loading)
        XCTAssertEqual(state.surchargeAmount, "+ $1.50")
    }

    @MainActor
    func test_PayPalState_statusEquality() {
        // Given
        let idle1 = PayPalState.Status.idle
        let idle2 = PayPalState.Status.idle
        let loading = PayPalState.Status.loading
        let failure1 = PayPalState.Status.failure("Error 1")
        let failure2 = PayPalState.Status.failure("Error 1")
        let failure3 = PayPalState.Status.failure("Error 2")

        // Then
        XCTAssertEqual(idle1, idle2)
        XCTAssertNotEqual(idle1, loading)
        XCTAssertEqual(failure1, failure2)
        XCTAssertNotEqual(failure1, failure3)
    }

    // MARK: - Helpers

    @MainActor
    private func createCheckoutScope() -> DefaultCheckoutScope {
        DefaultCheckoutScope(
            clientToken: "mock_token",
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )
    }
}
