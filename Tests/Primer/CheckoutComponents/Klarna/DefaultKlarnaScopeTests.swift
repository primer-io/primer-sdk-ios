//
//  DefaultKlarnaScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
final class DefaultKlarnaScopeTests: XCTestCase {

    private var mockInteractor: MockProcessKlarnaPaymentInteractor!
    private var checkoutScope: DefaultCheckoutScope?

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
        mockInteractor = MockProcessKlarnaPaymentInteractor()
    }

    override func tearDown() async throws {
        mockInteractor.release()
        mockInteractor = nil
        checkoutScope = nil
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

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

    // MARK: - Start Tests

    @MainActor
    func test_start_callsCreateSession() async throws {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        let scope = createScope()

        // When
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .categorySelection })

        // Then
        XCTAssertEqual(mockInteractor.createSessionCallCount, 1)
    }

    @MainActor
    func test_start_afterReentryWhileCreatingTheSession_keepsThatSession() async throws {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockInteractor.holdsCreateSession = true
        let scope = createScope()
        scope.start()
        try await awaitHeldCall()

        // When — the shopper returns to the list and picks Klarna again before the session exists
        scope.prepareForReentry()
        scope.start()
        // why: asserting that no second session starts, so give one time to reach the interactor
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockInteractor.createSessionCallCount, 1)
        mockInteractor.release()
        _ = try await awaitValue(scope.state, matching: { $0.step == .categorySelection })
    }

    // MARK: - State AsyncStream Tests

    @MainActor
    func test_state_emitsInitialState() async throws {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        let scope = createScope()

        // When
        let firstState = try await awaitFirst(scope.state)

        // Then
        XCTAssertNotNil(firstState)
    }

    // MARK: - selectPaymentCategory Tests

    @MainActor
    func test_selectPaymentCategory_withValidCategory_setsSelectedCategoryId() async throws {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockInteractor.paymentViewToReturn = UIView()
        let scope = createScope()
        scope.start()

        // Wait for session creation
        _ = try await awaitValue(scope.state, matching: { $0.step == .categorySelection })

        // When
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)

        // Wait for payment view load
        _ = try await awaitValue(scope.state, matching: { $0.step == .viewReady })

        // Then
        XCTAssertEqual(mockInteractor.configureForCategoryCallCount, 1)
        XCTAssertEqual(mockInteractor.lastCategoryId, KlarnaTestData.Constants.categoryPayNow)
        XCTAssertEqual(mockInteractor.lastClientToken, KlarnaTestData.Constants.clientToken)
    }

    @MainActor
    func test_selectPaymentCategory_withInvalidCategory_doesNotCallConfigure() async throws {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .categorySelection })

        // When
        scope.selectPaymentCategory("invalid_category_id")
        await Task.yield()

        // Then
        XCTAssertEqual(mockInteractor.configureForCategoryCallCount, 0)
    }

    // MARK: - Payment View Height Tests

    @MainActor
    func test_paymentViewHeight_reportedWhileTheViewLoads_isIgnored() async throws {
        // Given
        let scope = try await makeScopeLoadingCategory()

        // When
        mockInteractor.paymentViewHeightContinuation.yield(KlarnaTestData.Constants.paymentViewHeight)
        await Task.yield()
        let loading = try await awaitFirst(scope.state)
        mockInteractor.release()
        let loaded = try await awaitValue(scope.state) { $0.step == .viewReady }

        // Then
        XCTAssertEqual(loading.step, .categorySelection)
        XCTAssertEqual(loading.paymentViewHeight, 0)
        XCTAssertEqual(loaded.paymentViewHeight, 0)
        XCTAssertFalse(loaded.isSelectedOptionReady)
    }

    @MainActor
    func test_paymentViewHeight_reportedAfterTheViewLoads_makesTheOptionReady() async throws {
        // Given
        let scope = try await makeScopeWithLoadedView()

        // When
        mockInteractor.paymentViewHeightContinuation.yield(KlarnaTestData.Constants.paymentViewHeight)
        let state = try await awaitValue(scope.state) { $0.isSelectedOptionReady }

        // Then
        XCTAssertEqual(state.step, .viewReady)
        XCTAssertEqual(state.paymentViewHeight, KlarnaTestData.Constants.paymentViewHeight)
    }

    @MainActor
    func test_paymentViewHeight_notReportedInTime_fallsBackAndMakesTheOptionReady() async throws {
        // Given
        let scope = try await makeScopeWithLoadedView()

        // When
        mockInteractor.release()
        let state = try await awaitValue(scope.state) { $0.isSelectedOptionReady }

        // Then
        XCTAssertEqual(state.step, .viewReady)
        XCTAssertEqual(state.paymentViewHeight, DefaultKlarnaScope.fallbackPaymentViewHeight)
    }

    @MainActor
    func test_paymentViewHeight_reportedAfterTheFallback_replacesIt() async throws {
        // Given
        let scope = try await makeScopeWithLoadedView()
        mockInteractor.release()
        _ = try await awaitValue(scope.state) { $0.isSelectedOptionReady }

        // When
        mockInteractor.paymentViewHeightContinuation.yield(KlarnaTestData.Constants.paymentViewHeight)
        let state = try await awaitValue(scope.state) {
            $0.paymentViewHeight != DefaultKlarnaScope.fallbackPaymentViewHeight
        }

        // Then
        XCTAssertEqual(state.paymentViewHeight, KlarnaTestData.Constants.paymentViewHeight)
        XCTAssertTrue(state.isSelectedOptionReady)
    }

    @MainActor
    func test_paymentViewHeight_reportedInTime_isKeptWhenTheWaitEnds() async throws {
        // Given
        let scope = try await makeScopeWithLoadedView()
        mockInteractor.paymentViewHeightContinuation.yield(KlarnaTestData.Constants.paymentViewHeight)
        _ = try await awaitValue(scope.state) { $0.isSelectedOptionReady }

        // When
        mockInteractor.release()
        await Task.yield()
        let state = try await awaitFirst(scope.state)

        // Then
        XCTAssertEqual(state.paymentViewHeight, KlarnaTestData.Constants.paymentViewHeight)
    }

    @MainActor
    func test_isSelectedOptionReady_withoutAKlarnaView_isTrueOnceLoaded() async throws {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state) { $0.step == .categorySelection }

        // When
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        let state = try await awaitValue(scope.state) { $0.step == .viewReady }

        // Then
        XCTAssertTrue(state.isSelectedOptionReady)
        XCTAssertEqual(state.paymentViewHeight, 0)
    }

    @MainActor
    func test_selectPaymentCategory_afterAnotherIsReady_resetsTheHeightAndReadiness() async throws {
        // Given
        let scope = try await makeScopeOnKlarnaScreen()

        // When
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayLater)
        let state = try await awaitValue(scope.state) {
            $0.selectedCategoryId == KlarnaTestData.Constants.categoryPayLater
        }

        // Then
        XCTAssertEqual(state.paymentViewHeight, 0)
        XCTAssertFalse(state.isSelectedOptionReady)
    }

    // MARK: - authorizePayment Tests

    @MainActor
    func test_authorizePayment_whileTheViewLoads_doesNotAuthorize() async throws {
        // Given
        let scope = try await makeScopeLoadingCategory()

        // When
        scope.authorizePayment()
        await Task.yield()

        // Then
        let state = try await awaitFirst(scope.state)
        XCTAssertEqual(state.step, .categorySelection)
        XCTAssertEqual(mockInteractor.authorizeCallCount, 0)
    }

    @MainActor
    func test_authorizePayment_beforeTheViewIsMeasured_doesNotAuthorize() async throws {
        // Given
        let scope = try await makeScopeWithLoadedView()

        // When
        scope.authorizePayment()
        await Task.yield()

        // Then
        let state = try await awaitFirst(scope.state)
        XCTAssertEqual(state.step, .viewReady)
        XCTAssertEqual(mockInteractor.authorizeCallCount, 0)
    }

    @MainActor
    func test_authorizePayment_callsInteractorAuthorize() async throws {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockInteractor.paymentViewToReturn = UIView()
        mockInteractor.paymentResultToReturn = KlarnaTestData.successPaymentResult
        let authorizeExpectation = expectation(description: "authorize called")
        mockInteractor.onAuthorize = {
            authorizeExpectation.fulfill()
            return .approved(authToken: KlarnaTestData.Constants.authToken)
        }
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .categorySelection })

        // Select a category and wait for view to load
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        _ = try await awaitValue(scope.state, matching: { $0.step == .viewReady })
        try await measurePaymentView(of: scope)

        // When
        scope.authorizePayment()
        await fulfillment(of: [authorizeExpectation], timeout: 2.0)

        // Then
        XCTAssertEqual(mockInteractor.authorizeCallCount, 1)
    }

    @MainActor
    func test_authorizePayment_whenNotReady_doesNotCallAuthorize() async {
        // Given - scope in loading state (no session created yet)
        let scope = createScope()

        // When
        scope.authorizePayment()
        await Task.yield()

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
        await Task.yield()

        // Then
        XCTAssertEqual(mockInteractor.finalizeCallCount, 0)
    }

    // MARK: - submit Tests

    @MainActor
    func test_submit_callsAuthorizePayment() async throws {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockInteractor.paymentViewToReturn = UIView()
        mockInteractor.paymentResultToReturn = KlarnaTestData.successPaymentResult
        let authorizeExpectation = expectation(description: "authorize called")
        mockInteractor.onAuthorize = {
            authorizeExpectation.fulfill()
            return .approved(authToken: KlarnaTestData.Constants.authToken)
        }
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .categorySelection })

        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        _ = try await awaitValue(scope.state, matching: { $0.step == .viewReady })
        try await measurePaymentView(of: scope)

        // When
        scope.submit()
        await fulfillment(of: [authorizeExpectation], timeout: 2.0)

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
    func test_fullApprovedFlow_createSession_selectCategory_authorize_tokenize() async throws {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockInteractor.paymentViewToReturn = UIView()
        mockInteractor.authorizationResultToReturn = .approved(authToken: KlarnaTestData.Constants.authToken)
        let tokenizeExpectation = expectation(description: "tokenize called")
        mockInteractor.onTokenize = { _ in
            tokenizeExpectation.fulfill()
            return KlarnaTestData.successPaymentResult
        }
        let scope = createScope()

        // When - start creates session
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .categorySelection })

        // Select category
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        _ = try await awaitValue(scope.state, matching: { $0.step == .viewReady })
        try await measurePaymentView(of: scope)

        // Authorize
        scope.authorizePayment()
        await fulfillment(of: [tokenizeExpectation], timeout: 2.0)

        // Then
        XCTAssertEqual(mockInteractor.createSessionCallCount, 1)
        XCTAssertEqual(mockInteractor.configureForCategoryCallCount, 1)
        XCTAssertEqual(mockInteractor.authorizeCallCount, 1)
        XCTAssertEqual(mockInteractor.tokenizeCallCount, 1)
        XCTAssertEqual(mockInteractor.lastAuthToken, KlarnaTestData.Constants.authToken)
    }

    @MainActor
    func test_finalizationRequiredFlow_authorize_finalize_tokenize() async throws {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockInteractor.paymentViewToReturn = UIView()
        mockInteractor.authorizationResultToReturn = .finalizationRequired(authToken: KlarnaTestData.Constants.authToken)
        mockInteractor.finalizationResultToReturn = .approved(authToken: KlarnaTestData.Constants.authToken)
        let tokenizeExpectation = expectation(description: "tokenize called")
        mockInteractor.onTokenize = { _ in
            tokenizeExpectation.fulfill()
            return KlarnaTestData.successPaymentResult
        }
        let scope = createScope()

        // Start + session creation
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .categorySelection })

        // Select category + load view
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        _ = try await awaitValue(scope.state, matching: { $0.step == .viewReady })
        try await measurePaymentView(of: scope)

        // Authorize - should move to awaitingFinalization
        scope.authorizePayment()
        _ = try await awaitValue(scope.state, matching: { $0.step == .awaitingFinalization })

        // Finalize
        scope.finalizePayment()
        await fulfillment(of: [tokenizeExpectation], timeout: 2.0)

        // Then
        XCTAssertEqual(mockInteractor.authorizeCallCount, 1)
        XCTAssertEqual(mockInteractor.finalizeCallCount, 1)
        XCTAssertEqual(mockInteractor.tokenizeCallCount, 1)
    }

    // MARK: - Error Handling Tests

    @MainActor
    func test_createSession_failure_doesNotCrash() async {
        // Given
        let sessionExpectation = expectation(description: "create session called")
        mockInteractor.onCreateSession = {
            sessionExpectation.fulfill()
            throw TestError.networkFailure
        }
        let scope = createScope()

        // When
        scope.start()
        await fulfillment(of: [sessionExpectation], timeout: 2.0)

        // Then - should not crash, error handled internally
        XCTAssertEqual(mockInteractor.createSessionCallCount, 1)
    }

    @MainActor
    func test_configureForCategory_failure_revertsToSelection() async throws {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        let configureExpectation = expectation(description: "configure called")
        mockInteractor.onConfigureForCategory = { _, _ in
            configureExpectation.fulfill()
            throw TestError.networkFailure
        }
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .categorySelection })

        // When
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        await fulfillment(of: [configureExpectation], timeout: 2.0)

        // Then
        XCTAssertEqual(mockInteractor.configureForCategoryCallCount, 1)
    }

    @MainActor
    func test_authorize_failure_doesNotCrash() async throws {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockInteractor.paymentViewToReturn = UIView()
        let authorizeExpectation = expectation(description: "authorize called")
        mockInteractor.onAuthorize = {
            authorizeExpectation.fulfill()
            throw TestError.networkFailure
        }
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .categorySelection })
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        _ = try await awaitValue(scope.state, matching: { $0.step == .viewReady })
        try await measurePaymentView(of: scope)

        // When
        scope.authorizePayment()
        await fulfillment(of: [authorizeExpectation], timeout: 2.0)

        // Then - should not crash
        XCTAssertEqual(mockInteractor.authorizeCallCount, 1)
        XCTAssertEqual(mockInteractor.tokenizeCallCount, 0)
    }

    @MainActor
    func test_authorize_declined_doesNotTokenize() async throws {
        // Given
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockInteractor.paymentViewToReturn = UIView()
        let authorizeExpectation = expectation(description: "authorize called")
        mockInteractor.onAuthorize = {
            authorizeExpectation.fulfill()
            return .declined
        }
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .categorySelection })
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        _ = try await awaitValue(scope.state, matching: { $0.step == .viewReady })
        try await measurePaymentView(of: scope)

        // When
        scope.authorizePayment()
        await fulfillment(of: [authorizeExpectation], timeout: 2.0)

        // Then
        XCTAssertEqual(mockInteractor.authorizeCallCount, 1)
        XCTAssertEqual(mockInteractor.tokenizeCallCount, 0)
    }

    // MARK: - Leaving Klarna's Flow

    // Klarna reports Cancel on its consent alert or in its sheet as approved:false.
    @MainActor
    func test_authorize_declined_returnsToPaymentMethodSelection() async throws {
        // Given
        mockInteractor.authorizationResultToReturn = .declined
        let scope = try await makeScopeOnKlarnaScreen()

        // When
        let destination = try await destinationAfter { scope.authorizePayment() }

        // Then
        XCTAssertEqual(destination, .paymentMethodSelection)
    }

    @MainActor
    func test_authorize_declined_withoutAList_dismissesTheCheckout() async throws {
        // Given
        mockInteractor.authorizationResultToReturn = .declined
        let scope = try await makeScopeOnKlarnaScreen(presentationContext: .direct)

        // When
        let destination = try await destinationAfter { scope.authorizePayment() }

        // Then
        XCTAssertEqual(destination, .dismissed)
    }

    @MainActor
    func test_finalize_declined_returnsToPaymentMethodSelection() async throws {
        // Given
        mockInteractor.authorizationResultToReturn = .finalizationRequired(authToken: KlarnaTestData.Constants.authToken)
        mockInteractor.finalizationResultToReturn = .declined
        let scope = try await makeScopeOnKlarnaScreen()
        scope.authorizePayment()
        _ = try await awaitValue(scope.state) { $0.step == .awaitingFinalization }

        // When
        let destination = try await destinationAfter { scope.finalizePayment() }

        // Then
        XCTAssertEqual(destination, .paymentMethodSelection)
    }

    @MainActor
    func test_authorize_klarnaError_showsTheErrorScreen() async throws {
        // Given
        let error = PrimerError.klarnaError(message: "Klarna rejected the purchase")
        mockInteractor.authorizeError = error
        let scope = try await makeScopeOnKlarnaScreen()

        // When
        let destination = try await destinationAfter { scope.authorizePayment() }

        // Then
        XCTAssertEqual(destination, .failure(error))
    }

    // MARK: - Helper

    @MainActor
    private func awaitHeldCall(count: Int = 1) async throws {
        try await withTimeout(2.0) { [self] in
            while mockInteractor.heldCallCount < count { await Task.yield() }
        }
    }

    @MainActor
    private func measurePaymentView(of scope: DefaultKlarnaScope) async throws {
        mockInteractor.paymentViewHeightContinuation.yield(KlarnaTestData.Constants.paymentViewHeight)
        _ = try await awaitValue(scope.state) { $0.isSelectedOptionReady }
    }

    @MainActor
    private func makeScopeLoadingCategory(
        _ categoryId: String = KlarnaTestData.Constants.categoryPayNow
    ) async throws -> DefaultKlarnaScope {
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockInteractor.paymentViewToReturn = UIView()
        mockInteractor.holdsConfigureForCategory = true
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state) { $0.step == .categorySelection }
        scope.selectPaymentCategory(categoryId)
        try await awaitHeldCall()
        return scope
    }

    @MainActor
    private func makeScopeWithLoadedView() async throws -> DefaultKlarnaScope {
        let scope = try await makeScopeLoadingCategory()
        mockInteractor.release()
        _ = try await awaitValue(scope.state) { $0.step == .viewReady }
        try await awaitHeldCall()
        return scope
    }

    /// A scope whose category view is ready, on a live checkout that shows the Klarna screen.
    @MainActor
    private func makeScopeOnKlarnaScreen(
        presentationContext: PresentationContext = .fromPaymentSelection
    ) async throws -> DefaultKlarnaScope {
        mockInteractor.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockInteractor.paymentViewToReturn = UIView()
        let checkoutScope = try await ContainerTestHelpers.createSettledCheckoutScope()
        self.checkoutScope = checkoutScope
        let scope = DefaultKlarnaScope(
            checkoutScope: checkoutScope,
            presentationContext: presentationContext,
            processKlarnaInteractor: mockInteractor,
            waitForPaymentViewHeight: mockInteractor.waitForPaymentViewHeight
        )
        scope.start()
        _ = try await awaitValue(scope.state) { $0.step == .categorySelection }
        scope.selectPaymentCategory(KlarnaTestData.Constants.categoryPayNow)
        _ = try await awaitValue(scope.state) { $0.step == .viewReady }
        try await measurePaymentView(of: scope)
        checkoutScope.updateNavigationState(.paymentMethod(PrimerPaymentMethodType.klarna.rawValue))
        return scope
    }

    /// Where the checkout goes when it leaves the Klarna flow: the list, a dismissal or the error screen.
    @MainActor
    private func destinationAfter(_ action: () -> Void) async throws -> CheckoutNavigationState {
        let navigation = try XCTUnwrap(checkoutScope).navigationStateStream
        action()
        return try await awaitValue(navigation) {
            switch $0 {
            case .paymentMethodSelection, .dismissed, .failure: true
            default: false
            }
        }
    }

    @MainActor
    private func createScope(
        presentationContext: PresentationContext = .fromPaymentSelection
    ) -> DefaultKlarnaScope {
        let checkoutScope = DefaultCheckoutScope(
            clientToken: KlarnaTestData.Constants.mockToken,
            settings: PrimerSettings(),
            navigator: CheckoutNavigator()
        )

        return DefaultKlarnaScope(
            checkoutScope: checkoutScope,
            presentationContext: presentationContext,
            processKlarnaInteractor: mockInteractor,
            waitForPaymentViewHeight: mockInteractor.waitForPaymentViewHeight
        )
    }
}
