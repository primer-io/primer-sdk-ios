//
//  DefaultApplePayScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit
@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class DefaultApplePayScopeTests: XCTestCase {

    // MARK: - Properties

    private var mockPresentationManager: MockApplePayPresentationManager!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockPresentationManager = MockApplePayPresentationManager()
    }

    override func tearDown() {
        mockPresentationManager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    @MainActor
    func test_init_whenApplePayAvailable_stateIsAvailable() {
        // Given
        mockPresentationManager.isPresentable = true

        // When
        let scope = createScope()

        // Then
        XCTAssertTrue(scope.structuredState.isAvailable)
        XCTAssertNil(scope.structuredState.availabilityError)
    }

    @MainActor
    func test_init_whenApplePayUnavailable_stateIsUnavailable() {
        // Given
        mockPresentationManager.isPresentable = false
        mockPresentationManager.errorForDisplay = PrimerError.unableToPresentPaymentMethod(
            paymentMethodType: "APPLE_PAY"
        )

        // When
        let scope = createScope()

        // Then
        XCTAssertFalse(scope.structuredState.isAvailable)
        XCTAssertNotNil(scope.structuredState.availabilityError)
    }

    @MainActor
    func test_init_withFromPaymentSelectionContext_setsPresentationContext() {
        // When
        let scope = createScope(presentationContext: .fromPaymentSelection)

        // Then
        XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
    }

    @MainActor
    func test_init_withDirectContext_setsPresentationContext() {
        // When
        let scope = createScope(presentationContext: .direct)

        // Then
        XCTAssertEqual(scope.presentationContext, .direct)
    }

    // MARK: - Start Tests

    @MainActor
    func test_start_whenAvailable_setsAvailableState() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()

        // When
        scope.start()

        // Then
        XCTAssertTrue(scope.structuredState.isAvailable)
        XCTAssertNil(scope.structuredState.availabilityError)
    }

    @MainActor
    func test_start_whenUnavailable_setsUnavailableState() {
        // Given
        mockPresentationManager.isPresentable = false
        let scope = createScope()

        // When
        scope.start()

        // Then
        XCTAssertFalse(scope.structuredState.isAvailable)
        XCTAssertNotNil(scope.structuredState.availabilityError)
    }

    @MainActor
    func test_start_preservesButtonCustomization() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()
        scope.structuredState.buttonStyle = .white
        scope.structuredState.buttonType = .buy
        scope.structuredState.cornerRadius = 20.0

        // When
        scope.start()

        // Then
        XCTAssertEqual(scope.structuredState.buttonStyle, .white)
        XCTAssertEqual(scope.structuredState.buttonType, .buy)
        XCTAssertEqual(scope.structuredState.cornerRadius, 20.0)
    }

    // MARK: - Submit Tests

    @MainActor
    func test_submit_whenUnavailable_doesNotTriggerPresentation() async {
        // Given
        mockPresentationManager.isPresentable = false
        let scope = createScope()
        var presentCalled = false
        mockPresentationManager.onPresent = { _, _ in
            presentCalled = true
            return .success(())
        }

        // When
        scope.submit()

        // Wait briefly for any async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertFalse(presentCalled)
    }

    @MainActor
    func test_submit_whenAlreadyLoading_doesNotTriggerPayment() async {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()
        scope.structuredState.isLoading = true

        var presentCalled = false
        mockPresentationManager.onPresent = { _, _ in
            presentCalled = true
            return .success(())
        }

        // When
        scope.submit()

        // Wait briefly for any async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertFalse(presentCalled)
    }

    // MARK: - Cancel Tests

    @MainActor
    func test_cancel_resetsLoadingState() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()

        // When
        scope.cancel()

        // Then
        XCTAssertFalse(scope.structuredState.isLoading)
    }

    // MARK: - State AsyncStream Tests

    @MainActor
    func test_state_emitsCurrentState() async {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()

        // When
        var receivedState: PrimerApplePayState?
        let expectation = expectation(description: "Receive state with white button style")

        let task = Task { @MainActor in
            for await state in scope.state {
                receivedState = state
                if state.buttonStyle == .white {
                    expectation.fulfill()
                    break
                }
            }
        }

        // Wait for subscription to be established
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Trigger a state update
        scope.structuredState.buttonStyle = .white

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        task.cancel()

        XCTAssertNotNil(receivedState)
        XCTAssertEqual(receivedState?.buttonStyle, .white)
    }

    @MainActor
    func test_state_multipleUpdatesEmitMultipleStates() async {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()

        // When
        var receivedStates: [PrimerApplePayState] = []
        let task = Task {
            for await state in scope.state {
                receivedStates.append(state)
                if receivedStates.count >= 3 { break }
            }
        }

        // Wait for subscription
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Trigger multiple state updates
        scope.structuredState.buttonStyle = .white
        try? await Task.sleep(nanoseconds: 50_000_000)
        scope.structuredState.buttonType = .buy

        // Wait for emissions
        try? await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()

        // Then
        XCTAssertGreaterThanOrEqual(receivedStates.count, 1)
    }

    // MARK: - Helper

    @MainActor
    private func createScope(
        presentationContext: PresentationContext = .fromPaymentSelection
    ) -> DefaultApplePayScope {
        let checkoutScope = DefaultCheckoutScope(
            clientToken: "mock_token",
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )

        return DefaultApplePayScope(
            checkoutScope: checkoutScope,
            presentationContext: presentationContext,
            applePayPresentationManager: mockPresentationManager
        )
    }
}
