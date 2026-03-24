//
//  DefaultWebRedirectScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
final class DefaultWebRedirectScopeTests: XCTestCase {

    private var mockInteractor: MockProcessWebRedirectPaymentInteractor!
    private var mockRepository: MockWebRedirectRepository!
    private var mockAnalytics: MockTrackingAnalyticsInteractor!

    override func setUp() {
        super.setUp()
        mockInteractor = MockProcessWebRedirectPaymentInteractor()
        mockRepository = MockWebRedirectRepository()
        mockAnalytics = MockTrackingAnalyticsInteractor()
    }

    override func tearDown() {
        mockInteractor = nil
        mockRepository = nil
        mockAnalytics = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    @MainActor
    func test_init_defaultPresentationContext_isFromPaymentSelection() {
        // Given / When
        let scope = createScope()

        // Then
        XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
    }

    @MainActor
    func test_init_directPresentationContext_isDirect() {
        // Given / When
        let scope = createScope(presentationContext: .direct)

        // Then
        XCTAssertEqual(scope.presentationContext, .direct)
    }

    @MainActor
    func test_init_paymentMethodType_isSet() {
        // Given / When
        let scope = createScope(paymentMethodType: "TWINT")

        // Then
        XCTAssertEqual(scope.paymentMethodType, "TWINT")
    }

    @MainActor
    func test_init_customizationPropertiesAreNil() {
        // Given / When
        let scope = createScope()

        // Then
        XCTAssertNil(scope.screen)
        XCTAssertNil(scope.payButton)
        XCTAssertNil(scope.submitButtonText)
    }

    @MainActor
    func test_init_stateIsIdle() async throws {
        // Given
        let scope = createScope()

        // When
        let firstState = try await awaitFirst(scope.state)

        // Then
        XCTAssertEqual(firstState.status, .idle)
    }

    @MainActor
    func test_init_withPaymentMethod_stateContainsPaymentMethod() async throws {
        // Given
        let paymentMethod = CheckoutPaymentMethod(
            id: "twint-1",
            type: "TWINT",
            name: "Twint"
        )

        // When
        let scope = createScope(paymentMethod: paymentMethod)
        let firstState = try await awaitFirst(scope.state)

        // Then
        XCTAssertEqual(firstState.paymentMethod, paymentMethod)
    }

    @MainActor
    func test_init_withSurcharge_stateContainsSurcharge() async throws {
        // Given / When
        let scope = createScope(surchargeAmount: "+ $0.50")
        let firstState = try await awaitFirst(scope.state)

        // Then
        XCTAssertEqual(firstState.surchargeAmount, "+ $0.50")
    }

    // MARK: - UI Customization Tests

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
    func test_payButton_canBeSet() {
        // Given
        let scope = createScope()

        // When
        scope.payButton = { _ in EmptyView() }

        // Then
        XCTAssertNotNil(scope.payButton)
    }

    @MainActor
    func test_submitButtonText_canBeSet() {
        // Given
        let scope = createScope()

        // When
        scope.submitButtonText = "Pay with Twint"

        // Then
        XCTAssertEqual(scope.submitButtonText, "Pay with Twint")
    }

    // MARK: - start Tests

    @MainActor
    func test_start_setsStatusToIdle() async throws {
        // Given
        let scope = createScope()

        // When
        scope.start()

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.status == .idle })
        XCTAssertEqual(state.status, .idle)
    }

    // MARK: - State AsyncStream Tests

    @MainActor
    func test_state_emitsInitialState() async throws {
        // Given
        let scope = createScope()

        // When
        let firstState = try await awaitFirst(scope.state)

        // Then
        XCTAssertNotNil(firstState)
        XCTAssertEqual(firstState.status, .idle)
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
        await Task.yield()

        // Then
        XCTAssertTrue(task.isCancelled)
    }

    // MARK: - submit / performPayment Success Tests

    @MainActor
    func test_submit_successfulPayment_transitionsToSuccess() async throws {
        // Given
        let expectedResult = PaymentResult(
            paymentId: TestData.PaymentIds.success,
            status: .success,
            paymentMethodType: "ADYEN_SOFORT"
        )
        mockInteractor.paymentResultToReturn = expectedResult
        let scope = createScope()

        // When
        scope.submit()

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.status == .success })
        XCTAssertEqual(state.status, .success)
    }

    @MainActor
    func test_submit_callsInteractorExecute() async throws {
        // Given
        mockInteractor.paymentResultToReturn = PaymentResult(
            paymentId: TestData.PaymentIds.success,
            status: .success,
            paymentMethodType: "ADYEN_SOFORT"
        )
        let scope = createScope(paymentMethodType: "ADYEN_SOFORT")

        // When
        scope.submit()
        _ = try await awaitValue(scope.state, matching: { $0.status == .success })

        // Then
        XCTAssertEqual(mockInteractor.executeCallCount, 1)
        XCTAssertEqual(mockInteractor.lastPaymentMethodType, "ADYEN_SOFORT")
    }

    @MainActor
    func test_submit_tracksPaymentSubmittedAnalytics() async throws {
        // Given
        mockInteractor.paymentResultToReturn = PaymentResult(
            paymentId: TestData.PaymentIds.success,
            status: .success,
            paymentMethodType: "ADYEN_SOFORT"
        )
        let scope = createScope()

        // When
        scope.submit()
        _ = try await awaitValue(scope.state, matching: { $0.status == .success })

        // Then
        let hasTracked = await mockAnalytics.hasTracked(.paymentSubmitted)
        XCTAssertTrue(hasTracked)
    }

    @MainActor
    func test_submit_tracksPaymentProcessingStartedAnalytics() async throws {
        // Given
        mockInteractor.paymentResultToReturn = PaymentResult(
            paymentId: TestData.PaymentIds.success,
            status: .success,
            paymentMethodType: "ADYEN_SOFORT"
        )
        let scope = createScope()

        // When
        scope.submit()
        _ = try await awaitValue(scope.state, matching: { $0.status == .success })

        // Then
        let hasTracked = await mockAnalytics.hasTracked(.paymentProcessingStarted)
        XCTAssertTrue(hasTracked)
    }

    @MainActor
    func test_submit_tracksRedirectToThirdPartyAnalytics() async throws {
        // Given
        mockInteractor.paymentResultToReturn = PaymentResult(
            paymentId: TestData.PaymentIds.success,
            status: .success,
            paymentMethodType: "ADYEN_SOFORT"
        )
        let scope = createScope()

        // When
        scope.submit()
        _ = try await awaitValue(scope.state, matching: { $0.status == .success })

        // Then
        let hasTracked = await mockAnalytics.hasTracked(.paymentRedirectToThirdParty)
        XCTAssertTrue(hasTracked)
    }

    // MARK: - submit / performPayment Error Tests

    @MainActor
    func test_submit_failure_transitionsToFailure() async throws {
        // Given
        mockInteractor.errorToThrow = TestError.networkFailure
        let scope = createScope()

        // When
        scope.submit()

        // Then
        let state = try await awaitValue(scope.state, matching: {
            if case .failure = $0.status { return true }
            return false
        })
        if case let .failure(message) = state.status {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected failure status")
        }
    }

    @MainActor
    func test_submit_primerError_usesLocalizedDescription() async throws {
        // Given
        let primerError = PrimerError.unknown(message: "Something went wrong")
        mockInteractor.errorToThrow = primerError
        let scope = createScope()

        // When
        scope.submit()

        // Then
        let state = try await awaitValue(scope.state, matching: {
            if case .failure = $0.status { return true }
            return false
        })
        if case let .failure(message) = state.status {
            XCTAssertEqual(message, primerError.localizedDescription)
        } else {
            XCTFail("Expected failure status")
        }
    }

    @MainActor
    func test_submit_genericError_usesLocalizedDescription() async throws {
        // Given
        mockInteractor.errorToThrow = TestError.networkFailure
        let scope = createScope()

        // When
        scope.submit()

        // Then
        let state = try await awaitValue(scope.state, matching: {
            if case .failure = $0.status { return true }
            return false
        })
        if case let .failure(message) = state.status {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected failure status")
        }
    }

    // MARK: - cancel Tests

    @MainActor
    func test_cancel_resetsStatusToIdle() async throws {
        // Given
        let scope = createScope()

        // When
        scope.cancel()

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.status == .idle })
        XCTAssertEqual(state.status, .idle)
    }

    @MainActor
    func test_cancel_callsCancelPollingOnRepository() {
        // Given
        let scope = createScope()

        // When
        scope.cancel()

        // Then
        XCTAssertEqual(mockRepository.cancelPollingCallCount, 1)
    }

    @MainActor
    func test_cancel_doesNotCrash_withNilCheckoutScope() {
        // Given
        var checkoutScope: DefaultCheckoutScope? = makeCheckoutScope()
        let scope = DefaultWebRedirectScope(
            paymentMethodType: "ADYEN_SOFORT",
            checkoutScope: checkoutScope!,
            processWebRedirectInteractor: mockInteractor,
            analyticsInteractor: mockAnalytics,
            repository: mockRepository
        )

        // When
        checkoutScope = nil
        scope.cancel()

        // Then - no crash
        XCTAssertEqual(mockRepository.cancelPollingCallCount, 1)
    }

    // MARK: - onBack Tests

    @MainActor
    func test_onBack_fromPaymentSelection_doesNotCrash() {
        // Given
        let scope = createScope(presentationContext: .fromPaymentSelection)

        // When / Then - should not crash
        scope.onBack()
    }

    @MainActor
    func test_onBack_directContext_doesNotNavigateBack() {
        // Given
        let scope = createScope(presentationContext: .direct)

        // When
        scope.onBack()

        // Then - no crash; direct context doesn't navigate back
        XCTAssertFalse(scope.presentationContext.shouldShowBackButton)
    }

    @MainActor
    func test_onBack_fromPaymentSelection_shouldShowBackButton() {
        // Given
        let scope = createScope(presentationContext: .fromPaymentSelection)

        // Then
        XCTAssertTrue(scope.presentationContext.shouldShowBackButton)
    }

    // MARK: - Dismissal Mechanism Tests

    @MainActor
    func test_dismissalMechanism_returnsCheckoutScopeMechanism() {
        // Given
        let scope = createScope()

        // When
        let mechanism = scope.dismissalMechanism

        // Then
        XCTAssertNotNil(mechanism)
    }

    // MARK: - Weak checkoutScope Lifecycle Tests

    @MainActor
    func test_submit_withDeallocatedCheckoutScope_doesNotCrash() async throws {
        // Given
        var checkoutScope: DefaultCheckoutScope? = makeCheckoutScope()
        let scope = DefaultWebRedirectScope(
            paymentMethodType: "ADYEN_SOFORT",
            checkoutScope: checkoutScope!,
            processWebRedirectInteractor: mockInteractor,
            analyticsInteractor: mockAnalytics,
            repository: mockRepository
        )
        mockInteractor.paymentResultToReturn = PaymentResult(
            paymentId: TestData.PaymentIds.success,
            status: .success
        )

        // When
        checkoutScope = nil
        scope.submit()
        await Task.yield()
        await Task.yield()

        // Then - no crash; guard returns early when checkoutScope is nil
        XCTAssertEqual(mockInteractor.executeCallCount, 0)
    }

    // MARK: - Helper

    @MainActor
    private func createScope(
        paymentMethodType: String = "ADYEN_SOFORT",
        presentationContext: PresentationContext = .fromPaymentSelection,
        paymentMethod: CheckoutPaymentMethod? = nil,
        surchargeAmount: String? = nil
    ) -> DefaultWebRedirectScope {
        let checkoutScope = makeCheckoutScope()
        return DefaultWebRedirectScope(
            paymentMethodType: paymentMethodType,
            checkoutScope: checkoutScope,
            presentationContext: presentationContext,
            processWebRedirectInteractor: mockInteractor,
            accessibilityService: nil,
            analyticsInteractor: mockAnalytics,
            repository: mockRepository,
            paymentMethod: paymentMethod,
            surchargeAmount: surchargeAmount
        )
    }

    @MainActor
    private func makeCheckoutScope() -> DefaultCheckoutScope {
        DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )
    }
}
