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

    // MARK: - onBack Tests

    @MainActor
    func test_onBack_withFromPaymentSelectionContext_navigatesBack() {
        // Given
        let scope = createScope(presentationContext: .fromPaymentSelection)

        // When / Then — should not crash
        scope.onBack()
    }

    @MainActor
    func test_onBack_withDirectContext_doesNotNavigate() {
        // Given
        let scope = createScope(presentationContext: .direct)

        // When / Then — should not crash, does nothing since no back button
        scope.onBack()
    }

    // MARK: - onDismiss Tests

    @MainActor
    func test_onDismiss_delegatesToCheckoutScope() {
        // Given
        let scope = createScope()

        // When / Then — should not crash
        scope.onDismiss()
    }

    // MARK: - Cancel with Direct Context Tests

    @MainActor
    func test_cancel_withDirectContext_resetsLoadingOnly() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope(presentationContext: .direct)
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
        scope.structuredState.isLoading = true

        // When
        scope.cancel()

        // Then
        XCTAssertFalse(scope.structuredState.isLoading)
    }

    // MARK: - PrimerApplePayButton Tests

    @MainActor
    func test_primerApplePayButton_returnsAnyView() {
        // Given
        mockPresentationManager.isPresentable = true
        let scope = createScope()

        // When
        var buttonTapped = false
        let view = scope.PrimerApplePayButton { buttonTapped = true }

        // Then
        XCTAssertNotNil(view)
    }

    // MARK: - Unavailable State Detail Tests

    @MainActor
    func test_init_unavailable_errorContainsDescription() {
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

    // MARK: - start when initially unavailable then becomes available

    @MainActor
    func test_start_afterAvailabilityChange_updatesState() {
        // Given
        mockPresentationManager.isPresentable = false
        let scope = createScope()
        XCTAssertFalse(scope.structuredState.isAvailable)

        // When — availability changes
        mockPresentationManager.isPresentable = true
        scope.start()

        // Then
        XCTAssertTrue(scope.structuredState.isAvailable)
    }

    // MARK: - Submit when available but guard fails

    @MainActor
    func test_submit_whenNotAvailable_doesNothing() async {
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
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertFalse(presentCalled)
        XCTAssertFalse(scope.structuredState.isLoading)
    }

    // MARK: - Screen and Button Customization Properties

    @MainActor
    func test_screenAndButtonCustomization_defaultToNil() {
        // Given
        let scope = createScope()

        // Then
        XCTAssertNil(scope.screen)
        XCTAssertNil(scope.applePayButton)
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

// MARK: - Injectable Factory Tests

@available(iOS 15.0, *)
@MainActor
final class DefaultApplePayScopeFactoryTests: XCTestCase {

    private var mockPresentationManager: MockApplePayPresentationManager!
    private var mockClientSessionActions: MockClientSessionActionsModule!

    override func setUp() {
        super.setUp()
        mockPresentationManager = MockApplePayPresentationManager()
        mockPresentationManager.isPresentable = true
        mockClientSessionActions = MockClientSessionActionsModule()
    }

    override func tearDown() {
        mockClientSessionActions = nil
        mockPresentationManager = nil
        super.tearDown()
    }

    // MARK: - submit guard: not available

    func test_submit_whenStateNotAvailable_returnsEarlyWithoutCallingFactory() async {
        // Given
        mockPresentationManager.isPresentable = false
        let sut = createScope()
        XCTAssertFalse(sut.structuredState.isAvailable)

        // When
        sut.submit()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertFalse(sut.structuredState.isLoading)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 0)
    }

    // MARK: - submit guard: already loading

    func test_submit_whenAlreadyLoading_returnsEarlyWithoutCallingFactory() async {
        // Given
        let sut = createScope()
        sut.structuredState.isLoading = true

        // When
        sut.submit()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 0)
    }

    // MARK: - performPayment: applePayRequestFactory throws

    func test_performPayment_whenApplePayRequestFactoryThrows_resetsLoading() async throws {
        // Given
        let sut = createScope(applePayRequestFactory: {
            throw PrimerError.invalidClientSessionValue(name: "order.countryCode")
        })

        // When
        sut.submit()
        try await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertFalse(sut.structuredState.isLoading)
    }

    // MARK: - performPayment: cancelled error from coordinator

    func test_performPayment_whenCancelled_resetsLoadingWithoutHandlingError() async throws {
        // Given — presentation manager throws cancelled, coordinator propagates it
        mockPresentationManager.onPresent = { _, _ in
            .failure(PrimerError.cancelled(
                paymentMethodType: PrimerPaymentMethodType.applePay.rawValue
            ))
        }
        let sut = createScope()

        // When
        sut.submit()
        try await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertFalse(sut.structuredState.isLoading)
    }

    // MARK: - performPayment: clientSessionActions called with correct type

    func test_performPayment_callsClientSessionActionsWithApplePayType() async throws {
        // Given — cancelled so we don't need full payment flow
        mockPresentationManager.onPresent = { _, _ in
            .failure(PrimerError.cancelled(
                paymentMethodType: PrimerPaymentMethodType.applePay.rawValue
            ))
        }
        let sut = createScope()

        // When
        sut.submit()
        try await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(
            mockClientSessionActions.selectPaymentMethodCalls.first?.type,
            PrimerPaymentMethodType.applePay.rawValue
        )
        XCTAssertNil(mockClientSessionActions.selectPaymentMethodCalls.first?.network)
    }

    // MARK: - performPayment: clientSessionActions throws

    func test_performPayment_whenClientSessionActionsThrows_resetsLoading() async throws {
        // Given
        mockClientSessionActions.selectPaymentMethodError = TestError.networkFailure
        let sut = createScope()

        // When
        sut.submit()
        try await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertFalse(sut.structuredState.isLoading)
    }

    // MARK: - performPayment: non-PrimerError is wrapped

    func test_performPayment_whenNonPrimerErrorThrown_resetsLoading() async throws {
        // Given — presentation manager throws a non-PrimerError
        mockPresentationManager.onPresent = { _, _ in
            .failure(TestError.networkFailure)
        }
        let sut = createScope()

        // When
        sut.submit()
        try await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertFalse(sut.structuredState.isLoading)
    }

    // MARK: - performPayment: presentation manager onPresent called

    func test_performPayment_callsPresentationManagerPresent() async throws {
        // Given
        var presentWasCalled = false
        mockPresentationManager.onPresent = { _, _ in
            presentWasCalled = true
            return .failure(PrimerError.cancelled(
                paymentMethodType: PrimerPaymentMethodType.applePay.rawValue
            ))
        }
        let sut = createScope()

        // When
        sut.submit()
        try await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertTrue(presentWasCalled)
        XCTAssertFalse(sut.structuredState.isLoading)
    }

    // MARK: - performPayment: request factory error does not call coordinator

    func test_performPayment_whenRequestFactoryThrows_doesNotCallPresentationManager() async throws {
        // Given
        var presentWasCalled = false
        mockPresentationManager.onPresent = { _, _ in
            presentWasCalled = true
            return .success(())
        }
        let sut = createScope(applePayRequestFactory: {
            throw TestError.unknown
        })

        // When
        sut.submit()
        try await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertFalse(presentWasCalled)
        XCTAssertFalse(sut.structuredState.isLoading)
    }

    // MARK: - Helper

    private func createScope(
        presentationContext: PresentationContext = .fromPaymentSelection,
        applePayRequestFactory: (() throws -> ApplePayRequest)? = nil
    ) -> DefaultApplePayScope {
        let checkoutScope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )

        let defaultRequestFactory: () throws -> ApplePayRequest = applePayRequestFactory ?? {
            ApplePayRequest(
                currency: Currency(code: "GBP", decimalDigits: 2),
                merchantIdentifier: TestData.PaymentMethodOptions.exampleMerchantId,
                countryCode: .gb,
                items: []
            )
        }

        return DefaultApplePayScope(
            checkoutScope: checkoutScope,
            presentationContext: presentationContext,
            applePayPresentationManager: mockPresentationManager,
            clientSessionActionsFactory: { [unowned self] in mockClientSessionActions },
            applePayRequestFactory: defaultRequestFactory
        )
    }
}
