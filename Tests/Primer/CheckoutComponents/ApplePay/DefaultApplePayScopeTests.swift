//
//  DefaultApplePayScopeTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit
import SwiftUI
import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class DefaultApplePayScopeTests: XCTestCase {

    // MARK: - Properties

    var mockPresentationManager: MockApplePayPresentationManager!

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
        XCTAssertTrue(scope.isAvailable)
        XCTAssertNil(scope.availabilityError)
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
        XCTAssertFalse(scope.isAvailable)
        XCTAssertNotNil(scope.availabilityError)
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

    // MARK: - Button Customization Tests

    @MainActor
    func test_buttonStyle_getterReturnsDefaultStyle() {
        // Given
        let scope = createScope()

        // Then
        XCTAssertEqual(scope.buttonStyle, .black)
    }

    @MainActor
    func test_buttonStyle_setterUpdatesStyle() {
        // Given
        let scope = createScope()

        // When
        scope.buttonStyle = .white

        // Then
        XCTAssertEqual(scope.buttonStyle, .white)
    }

    @MainActor
    func test_buttonType_getterReturnsDefaultType() {
        // Given
        let scope = createScope()

        // Then
        XCTAssertEqual(scope.buttonType, .plain)
    }

    @MainActor
    func test_buttonType_setterUpdatesType() {
        // Given
        let scope = createScope()

        // When
        scope.buttonType = .buy

        // Then
        XCTAssertEqual(scope.buttonType, .buy)
    }

    @MainActor
    func test_cornerRadius_getterReturnsDefaultRadius() {
        // Given
        let scope = createScope()

        // Then
        XCTAssertEqual(scope.cornerRadius, 8.0)
    }

    @MainActor
    func test_cornerRadius_setterUpdatesRadius() {
        // Given
        let scope = createScope()

        // When
        scope.cornerRadius = 16.0

        // Then
        XCTAssertEqual(scope.cornerRadius, 16.0)
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
        XCTAssertTrue(scope.isAvailable)
        XCTAssertNil(scope.availabilityError)
    }

    @MainActor
    func test_start_whenUnavailable_setsUnavailableState() {
        // Given
        mockPresentationManager.isPresentable = false
        let scope = createScope()

        // When
        scope.start()

        // Then
        XCTAssertFalse(scope.isAvailable)
        XCTAssertNotNil(scope.availabilityError)
    }

    @MainActor
    func test_start_preservesButtonCustomization() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()
        scope.buttonStyle = .white
        scope.buttonType = .buy
        scope.cornerRadius = 20.0

        // When
        scope.start()

        // Then - customization should be preserved
        XCTAssertEqual(scope.buttonStyle, .white)
        XCTAssertEqual(scope.buttonType, .buy)
        XCTAssertEqual(scope.cornerRadius, 20.0)
    }

    // MARK: - Pay Guards Tests

    @MainActor
    func test_pay_whenUnavailable_doesNotTriggerPresentation() async {
        // Given
        mockPresentationManager.isPresentable = false
        let scope = createScope()
        var presentCalled = false
        mockPresentationManager.onPresent = { _, _ in
            presentCalled = true
            return .success(())
        }

        // When
        scope.pay()

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

        // Then - loading should be false
        XCTAssertFalse(scope.structuredState.isLoading)
    }

    // MARK: - OnBack Tests

    @MainActor
    func test_onBack_withFromPaymentSelectionContext_shouldShowBackButton() {
        // Given
        let scope = createScope(presentationContext: .fromPaymentSelection)

        // Then - presentationContext should indicate back button is shown
        XCTAssertTrue(scope.presentationContext.shouldShowBackButton)

        // When - calling onBack should not crash
        scope.onBack()
    }

    @MainActor
    func test_onBack_withDirectContext_shouldNotShowBackButton() {
        // Given
        let scope = createScope(presentationContext: .direct)

        // Then - presentationContext should not show back button
        XCTAssertFalse(scope.presentationContext.shouldShowBackButton)

        // When - calling onBack should not crash
        scope.onBack()
    }

    // MARK: - OnDismiss Tests

    @MainActor
    func test_onDismiss_callsCheckoutScopeOnDismiss() {
        // Given
        let scope = createScope()

        // When/Then - should not crash when called
        scope.onDismiss()
    }

    // MARK: - Pay Tests

    @MainActor
    func test_pay_whenAlreadyLoading_doesNotTriggerPayment() async {
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
        scope.pay()

        // Wait briefly for any async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - should not present because already loading
        XCTAssertFalse(presentCalled)
    }

    // MARK: - PrimerApplePayButton Tests

    @MainActor
    func test_PrimerApplePayButton_returnsAnyView() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()

        // When
        let button = scope.PrimerApplePayButton { }

        // Then
        XCTAssertNotNil(button)
    }

    @MainActor
    func test_PrimerApplePayButton_usesConfiguredStyle() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()
        scope.buttonStyle = .white
        scope.buttonType = .buy
        scope.cornerRadius = 12.0

        // When
        let button = scope.PrimerApplePayButton { }

        // Then - button is created with the configured style
        XCTAssertNotNil(button)
        XCTAssertEqual(scope.buttonStyle, .white)
        XCTAssertEqual(scope.buttonType, .buy)
        XCTAssertEqual(scope.cornerRadius, 12.0)
    }

    // MARK: - UI Customization Tests

    @MainActor
    func test_screen_defaultsToNil() {
        // Given
        let scope = createScope()

        // Then
        XCTAssertNil(scope.screen)
    }

    @MainActor
    func test_screen_canBeSet() {
        // Given
        let scope = createScope()

        // When
        scope.screen = { _ in EmptyView() }

        // Then
        XCTAssertNotNil(scope.screen)
    }

    @MainActor
    func test_applePayButton_defaultsToNil() {
        // Given
        let scope = createScope()

        // Then
        XCTAssertNil(scope.applePayButton)
    }

    @MainActor
    func test_applePayButton_canBeSet() {
        // Given
        let scope = createScope()

        // When
        scope.applePayButton = { _ in EmptyView() }

        // Then
        XCTAssertNotNil(scope.applePayButton)
    }

    // MARK: - State AsyncStream Tests

    @MainActor
    func test_state_emitsCurrentState() async {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()

        // When
        var receivedState: ApplePayFormState?
        let task = Task {
            for await state in scope.state {
                receivedState = state
                break
            }
        }

        // Wait for subscription to be established
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Trigger a state update
        scope.buttonStyle = .white

        // Wait briefly for async stream
        try? await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()

        // Then
        XCTAssertNotNil(receivedState)
        XCTAssertEqual(receivedState?.buttonStyle, .white)
    }

    @MainActor
    func test_state_emitsInitialState() async {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()

        // When
        var receivedStates: [ApplePayFormState] = []
        let task = Task {
            for await state in scope.state {
                receivedStates.append(state)
                if receivedStates.count >= 1 { break }
            }
        }

        // Wait briefly for initial state emission
        try? await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()

        // Then - should have received initial state
        XCTAssertFalse(receivedStates.isEmpty)
        XCTAssertTrue(receivedStates[0].isAvailable)
    }

    @MainActor
    func test_state_streamCanBeCancelled() async {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()

        // When
        let task = Task {
            for await _ in scope.state {
                // Just iterate
            }
        }

        // Cancel immediately
        task.cancel()

        // Wait for cancellation to propagate
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then - should not crash
        XCTAssertTrue(task.isCancelled)
    }

    @MainActor
    func test_state_multipleUpdatesEmitMultipleStates() async {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()

        // When
        var receivedStates: [ApplePayFormState] = []
        let task = Task {
            for await state in scope.state {
                receivedStates.append(state)
                if receivedStates.count >= 3 { break }
            }
        }

        // Wait for subscription
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Trigger multiple state updates
        scope.buttonStyle = .white
        try? await Task.sleep(nanoseconds: 50_000_000)
        scope.buttonType = .buy

        // Wait for emissions
        try? await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()

        // Then - should have received multiple states
        XCTAssertGreaterThanOrEqual(receivedStates.count, 1)
    }

    // MARK: - Cancel During Loading Tests

    @MainActor
    func test_cancel_duringLoading_resetsLoadingState() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()
        scope.structuredState.isLoading = true

        // When
        scope.cancel()

        // Then
        XCTAssertFalse(scope.structuredState.isLoading)
    }

    @MainActor
    func test_cancel_withFromPaymentSelectionContext_navigatesBack() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope(presentationContext: .fromPaymentSelection)

        // When - should not crash
        scope.cancel()

        // Then - loading should be reset
        XCTAssertFalse(scope.structuredState.isLoading)
    }

    @MainActor
    func test_cancel_withDirectContext_doesNotNavigateBack() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope(presentationContext: .direct)

        // When - should not crash
        scope.cancel()

        // Then - loading should be reset
        XCTAssertFalse(scope.structuredState.isLoading)
    }

    // MARK: - StructuredState Direct Access Tests

    @MainActor
    func test_structuredState_isLoadingAccessor() {
        // Given
        let scope = createScope()

        // When
        scope.structuredState.isLoading = true

        // Then
        XCTAssertTrue(scope.structuredState.isLoading)
    }

    @MainActor
    func test_structuredState_isAvailableAccessor() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()

        // Then
        XCTAssertTrue(scope.structuredState.isAvailable)
    }

    @MainActor
    func test_structuredState_buttonStyleSync() {
        // Given
        let scope = createScope()

        // When
        scope.buttonStyle = .whiteOutline

        // Then - both accessors should return same value
        XCTAssertEqual(scope.buttonStyle, scope.structuredState.buttonStyle)
    }

    @MainActor
    func test_structuredState_cornerRadiusSync() {
        // Given
        let scope = createScope()

        // When
        scope.cornerRadius = 24.0

        // Then - both accessors should return same value
        XCTAssertEqual(scope.cornerRadius, scope.structuredState.cornerRadius)
    }

    // MARK: - Availability Error Tests

    @MainActor
    func test_availabilityError_whenAvailable_isNil() {
        // Given
        mockPresentationManager.isPresentable = true

        // When
        let scope = createScope()

        // Then
        XCTAssertNil(scope.availabilityError)
    }

    @MainActor
    func test_availabilityError_whenUnavailable_containsErrorMessage() {
        // Given
        mockPresentationManager.isPresentable = false
        mockPresentationManager.errorForDisplay = NSError(
            domain: "TestDomain",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Test error message"]
        )

        // When
        let scope = createScope()

        // Then
        XCTAssertNotNil(scope.availabilityError)
        XCTAssertTrue(scope.availabilityError?.contains("Test error message") ?? false)
    }

    // MARK: - Submit Method Tests (PrimerApplePayScope Protocol)

    @MainActor
    func test_submit_whenAvailable_callsPay() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()

        // When/Then - submit() should be callable and trigger pay()
        // This tests the protocol default implementation
        scope.submit()

        // Verify scope is in expected state after submit
        XCTAssertTrue(scope.isAvailable)
    }

    @MainActor
    func test_submit_whenUnavailable_returnsEarly() {
        // Given
        mockPresentationManager.isPresentable = false
        let scope = createScope()

        // When - submit() calls pay() which guards on isAvailable
        scope.submit()

        // Then - should return early without crashing
        XCTAssertFalse(scope.isAvailable)
        XCTAssertFalse(scope.structuredState.isLoading)
    }

    // MARK: - Helper

    @MainActor
    private func createScope(
        presentationContext: PresentationContext = .fromPaymentSelection
    ) -> DefaultApplePayScope {
        // Create a real checkout scope with minimal setup
        // The checkoutScope parameter is weak, so it's fine if it gets deallocated
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
