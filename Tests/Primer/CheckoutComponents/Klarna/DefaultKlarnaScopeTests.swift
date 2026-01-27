//
//  DefaultKlarnaScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
final class DefaultKlarnaScopeTests: XCTestCase {

    // MARK: - Properties

    var mockInteractor: MockProcessKlarnaPaymentInteractor!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockInteractor = MockProcessKlarnaPaymentInteractor()
    }

    override func tearDown() {
        mockInteractor = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    @MainActor
    func test_init_defaultPresentationContext_isFromPaymentSelection() {
        let scope = createScope()
        XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
    }

    @MainActor
    func test_init_directPresentationContext_isDirect() {
        let scope = createScope(presentationContext: .direct)
        XCTAssertEqual(scope.presentationContext, .direct)
    }

    @MainActor
    func test_init_paymentViewIsNil() {
        let scope = createScope()
        XCTAssertNil(scope.paymentView)
    }

    @MainActor
    func test_init_customizationPropertiesAreNil() {
        let scope = createScope()
        XCTAssertNil(scope.screen)
        XCTAssertNil(scope.authorizeButton)
        XCTAssertNil(scope.finalizeButton)
    }

    // MARK: - UI Customization Tests

    @MainActor
    func test_screen_canBeSet() {
        let scope = createScope()
        scope.screen = { _ in EmptyView() }
        XCTAssertNotNil(scope.screen)
    }

    @MainActor
    func test_authorizeButton_canBeSet() {
        let scope = createScope()
        scope.authorizeButton = { _ in EmptyView() }
        XCTAssertNotNil(scope.authorizeButton)
    }

    @MainActor
    func test_finalizeButton_canBeSet() {
        let scope = createScope()
        scope.finalizeButton = { _ in EmptyView() }
        XCTAssertNotNil(scope.finalizeButton)
    }

    // MARK: - Start Tests

    @MainActor
    func test_start_callsCreateSession() async {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        let scope = createScope()

        // When
        scope.start()

        // Wait for async session creation
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockInteractor.createSessionCallCount, 1)
    }

    // MARK: - State AsyncStream Tests

    @MainActor
    func test_state_emitsInitialState() async {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        let scope = createScope()

        // When
        var receivedStates: [KlarnaState] = []
        let task = Task {
            for await state in scope.state {
                receivedStates.append(state)
                if receivedStates.count >= 1 { break }
            }
        }

        // Wait for initial emission
        try? await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()

        // Then
        XCTAssertFalse(receivedStates.isEmpty)
    }

    @MainActor
    func test_state_streamCanBeCancelled() async {
        // Given
        let scope = createScope()

        // When
        let task = Task {
            for await _ in scope.state {
                // Just iterate
            }
        }

        task.cancel()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then
        XCTAssertTrue(task.isCancelled)
    }

    // MARK: - selectPaymentCategory Tests

    @MainActor
    func test_selectPaymentCategory_withValidCategory_setsSelectedCategoryId() async {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockInteractor.paymentViewToReturn = UIView()
        let scope = createScope()
        scope.start()

        // Wait for session creation
        try? await Task.sleep(nanoseconds: 200_000_000)

        // When
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)

        // Wait for payment view load
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockInteractor.configureForCategoryCallCount, 1)
        XCTAssertEqual(mockInteractor.lastCategoryId, KlarnaTestData.Constants.categoryPayNow)
        XCTAssertEqual(mockInteractor.lastClientToken, KlarnaTestData.Constants.clientToken)
    }

    @MainActor
    func test_selectPaymentCategory_withInvalidCategory_doesNotCallConfigure() async {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        let scope = createScope()
        scope.start()

        // Wait for session creation
        try? await Task.sleep(nanoseconds: 200_000_000)

        // When
        scope.selectPaymentCategory("invalid_category_id")

        // Wait to verify no calls
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockInteractor.configureForCategoryCallCount, 0)
    }

    // MARK: - authorizePayment Tests

    @MainActor
    func test_authorizePayment_callsInteractorAuthorize() async {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockInteractor.paymentViewToReturn = UIView()
        mockInteractor.authorizationResultToReturn = .approved(authToken: KlarnaTestData.Constants.authToken)
        mockInteractor.paymentResultToReturn = KlarnaTestData.successPaymentResult
        let scope = createScope()
        scope.start()

        // Wait for session creation
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Select a category and wait for view to load
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // When
        scope.authorizePayment()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockInteractor.authorizeCallCount, 1)
    }

    @MainActor
    func test_authorizePayment_whenNotReady_doesNotCallAuthorize() async {
        // Given - scope in loading state (no session created yet)
        let scope = createScope()

        // When
        scope.authorizePayment()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockInteractor.authorizeCallCount, 0)
    }

    // MARK: - finalizePayment Tests

    @MainActor
    func test_finalizePayment_whenNotAwaitingFinalization_doesNotCallFinalize() async {
        // Given
        let scope = createScope()

        // When
        scope.finalizePayment()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockInteractor.finalizeCallCount, 0)
    }

    // MARK: - submit Tests

    @MainActor
    func test_submit_callsAuthorizePayment() async {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockInteractor.paymentViewToReturn = UIView()
        mockInteractor.authorizationResultToReturn = .approved(authToken: KlarnaTestData.Constants.authToken)
        mockInteractor.paymentResultToReturn = KlarnaTestData.successPaymentResult
        let scope = createScope()
        scope.start()

        // Wait for session + category selection + view load
        try? await Task.sleep(nanoseconds: 200_000_000)
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // When
        scope.submit()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockInteractor.authorizeCallCount, 1)
    }

    // MARK: - Navigation Tests

    @MainActor
    func test_onBack_withFromPaymentSelectionContext_shouldShowBackButton() {
        let scope = createScope(presentationContext: .fromPaymentSelection)
        XCTAssertTrue(scope.presentationContext.shouldShowBackButton)

        // Should not crash
        scope.onBack()
    }

    @MainActor
    func test_onBack_withDirectContext_shouldNotShowBackButton() {
        let scope = createScope(presentationContext: .direct)
        XCTAssertFalse(scope.presentationContext.shouldShowBackButton)

        // Should not crash
        scope.onBack()
    }

    @MainActor
    func test_onCancel_shouldNotCrash() {
        let scope = createScope()
        // Should not crash
        scope.onCancel()
    }

    @MainActor
    func test_cancel_shouldNotCrash() {
        let scope = createScope()
        // Should not crash
        scope.cancel()
    }

    // MARK: - Dismissal Mechanism Tests

    @MainActor
    func test_dismissalMechanism_returnsCheckoutScopeDismissalMechanism() {
        let scope = createScope()
        // dismissalMechanism comes from checkoutScope, which may be nil after weak dealloc
        let mechanism = scope.dismissalMechanism
        XCTAssertNotNil(mechanism)
    }

    // MARK: - Full Flow Integration Tests

    @MainActor
    func test_fullApprovedFlow_createSession_selectCategory_authorize_tokenize() async {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockInteractor.paymentViewToReturn = UIView()
        mockInteractor.authorizationResultToReturn = .approved(authToken: KlarnaTestData.Constants.authToken)
        mockInteractor.paymentResultToReturn = KlarnaTestData.successPaymentResult
        let scope = createScope()

        // When - start creates session
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Select category
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Authorize
        scope.authorizePayment()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertEqual(mockInteractor.createSessionCallCount, 1)
        XCTAssertEqual(mockInteractor.configureForCategoryCallCount, 1)
        XCTAssertEqual(mockInteractor.authorizeCallCount, 1)
        XCTAssertEqual(mockInteractor.tokenizeCallCount, 1)
        XCTAssertEqual(mockInteractor.lastAuthToken, KlarnaTestData.Constants.authToken)
    }

    @MainActor
    func test_finalizationRequiredFlow_authorize_finalize_tokenize() async {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockInteractor.paymentViewToReturn = UIView()
        mockInteractor.authorizationResultToReturn = .finalizationRequired(authToken: KlarnaTestData.Constants.authToken)
        mockInteractor.finalizationResultToReturn = .approved(authToken: KlarnaTestData.Constants.authToken)
        mockInteractor.paymentResultToReturn = KlarnaTestData.successPaymentResult
        let scope = createScope()

        // Start + session creation
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Select category + load view
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Authorize - should move to awaitingFinalization
        scope.authorizePayment()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Finalize
        scope.finalizePayment()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertEqual(mockInteractor.authorizeCallCount, 1)
        XCTAssertEqual(mockInteractor.finalizeCallCount, 1)
        XCTAssertEqual(mockInteractor.tokenizeCallCount, 1)
    }

    // MARK: - Error Handling Tests

    @MainActor
    func test_createSession_failure_doesNotCrash() async {
        // Given
        mockInteractor.createSessionError = TestError.networkFailure
        let scope = createScope()

        // When
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then - should not crash, error handled internally
        XCTAssertEqual(mockInteractor.createSessionCallCount, 1)
    }

    @MainActor
    func test_configureForCategory_failure_revertsToSelection() async {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockInteractor.configureForCategoryError = TestError.networkFailure
        let scope = createScope()
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // When
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockInteractor.configureForCategoryCallCount, 1)
    }

    @MainActor
    func test_authorize_failure_doesNotCrash() async {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockInteractor.paymentViewToReturn = UIView()
        mockInteractor.authorizeError = TestError.networkFailure
        let scope = createScope()
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // When
        scope.authorizePayment()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then - should not crash
        XCTAssertEqual(mockInteractor.authorizeCallCount, 1)
        XCTAssertEqual(mockInteractor.tokenizeCallCount, 0)
    }

    @MainActor
    func test_authorize_declined_doesNotTokenize() async {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockInteractor.paymentViewToReturn = UIView()
        mockInteractor.authorizationResultToReturn = .declined
        let scope = createScope()
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // When
        scope.authorizePayment()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockInteractor.authorizeCallCount, 1)
        XCTAssertEqual(mockInteractor.tokenizeCallCount, 0)
    }

    // MARK: - Helper

    @MainActor
    private func createScope(
        presentationContext: PresentationContext = .fromPaymentSelection
    ) -> DefaultKlarnaScope {
        let checkoutScope = DefaultCheckoutScope(
            clientToken: "mock_token",
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )

        return DefaultKlarnaScope(
            checkoutScope: checkoutScope,
            presentationContext: presentationContext,
            processKlarnaInteractor: mockInteractor
        )
    }
}
