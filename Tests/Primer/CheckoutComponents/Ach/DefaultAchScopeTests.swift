//
//  DefaultAchScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
final class DefaultAchScopeTests: XCTestCase {

    // MARK: - Properties

    var mockInteractor: MockProcessAchPaymentInteractor!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockInteractor = MockProcessAchPaymentInteractor()
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
    func test_init_bankCollectorViewControllerIsNil() {
        let scope = createScope()
        XCTAssertNil(scope.bankCollectorViewController)
    }

    @MainActor
    func test_init_customizationPropertiesAreNil() {
        let scope = createScope()
        XCTAssertNil(scope.screen)
        XCTAssertNil(scope.userDetailsScreen)
        XCTAssertNil(scope.mandateScreen)
        XCTAssertNil(scope.submitButton)
    }

    // MARK: - UI Customization Tests

    @MainActor
    func test_screen_canBeSet() {
        let scope = createScope()
        scope.screen = { _ in EmptyView() }
        XCTAssertNotNil(scope.screen)
    }

    @MainActor
    func test_userDetailsScreen_canBeSet() {
        let scope = createScope()
        scope.userDetailsScreen = { _ in EmptyView() }
        XCTAssertNotNil(scope.userDetailsScreen)
    }

    @MainActor
    func test_mandateScreen_canBeSet() {
        let scope = createScope()
        scope.mandateScreen = { _ in EmptyView() }
        XCTAssertNotNil(scope.mandateScreen)
    }

    @MainActor
    func test_submitButton_canBeSet() {
        let scope = createScope()
        scope.submitButton = { _ in EmptyView() }
        XCTAssertNotNil(scope.submitButton)
    }

    // MARK: - Start Tests

    @MainActor
    func test_start_callsValidate() async {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        let scope = createScope()

        // When
        scope.start()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockInteractor.validateCallCount, 1)
    }

    @MainActor
    func test_start_callsLoadUserDetails() async {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        let scope = createScope()

        // When
        scope.start()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockInteractor.loadUserDetailsCallCount, 1)
    }

    @MainActor
    func test_start_transitionsToUserDetailsCollection() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        let scope = createScope()

        // When
        scope.start()

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })
        XCTAssertEqual(state.step, .userDetailsCollection)
    }

    @MainActor
    func test_start_populatesUserDetails() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        let scope = createScope()

        // When
        scope.start()

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })
        XCTAssertEqual(state.userDetails.firstName, AchTestData.Constants.firstName)
        XCTAssertEqual(state.userDetails.lastName, AchTestData.Constants.lastName)
        XCTAssertEqual(state.userDetails.emailAddress, AchTestData.Constants.emailAddress)
    }

    @MainActor
    func test_start_withValidUserDetails_enablesSubmit() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        let scope = createScope()

        // When
        scope.start()

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })
        XCTAssertTrue(state.isSubmitEnabled)
    }

    @MainActor
    func test_start_withEmptyUserDetails_disablesSubmit() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.emptyUserDetails
        let scope = createScope()

        // When
        scope.start()

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })
        XCTAssertFalse(state.isSubmitEnabled)
    }

    // MARK: - User Details Update Tests

    @MainActor
    func test_updateFirstName_updatesState() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.emptyUserDetails
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })

        // When
        scope.updateFirstName("John")

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.userDetails.firstName == "John" })
        XCTAssertEqual(state.userDetails.firstName, "John")
    }

    @MainActor
    func test_updateLastName_updatesState() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.emptyUserDetails
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })

        // When
        scope.updateLastName("Doe")

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.userDetails.lastName == "Doe" })
        XCTAssertEqual(state.userDetails.lastName, "Doe")
    }

    @MainActor
    func test_updateEmailAddress_updatesState() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.emptyUserDetails
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })

        // When
        scope.updateEmailAddress("john@example.com")

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.userDetails.emailAddress == "john@example.com" })
        XCTAssertEqual(state.userDetails.emailAddress, "john@example.com")
    }

    @MainActor
    func test_updateUserDetails_withValidValues_enablesSubmit() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.emptyUserDetails
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })

        // When
        scope.updateFirstName("John")
        scope.updateLastName("Doe")
        scope.updateEmailAddress("john@example.com")

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.isSubmitEnabled == true })
        XCTAssertTrue(state.isSubmitEnabled)
    }

    @MainActor
    func test_updateFirstName_withInvalidValue_setsFirstNameError() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.emptyUserDetails
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })

        // When
        scope.updateFirstName("John123")

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.fieldValidation?.firstNameError != nil })
        XCTAssertNotNil(state.fieldValidation?.firstNameError)
    }

    @MainActor
    func test_updateEmailAddress_withInvalidValue_setsEmailError() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.emptyUserDetails
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })

        // When
        scope.updateEmailAddress("not-an-email")

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.fieldValidation?.emailError != nil })
        XCTAssertNotNil(state.fieldValidation?.emailError)
    }

    // MARK: - Submit User Details Tests

    @MainActor
    func test_submitUserDetails_callsPatchUserDetails() async {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.bankCollectorViewControllerToReturn = UIViewController()
        let scope = createScope()
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // When
        scope.submitUserDetails()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockInteractor.patchUserDetailsCallCount, 1)
    }

    @MainActor
    func test_submitUserDetails_capturesUserDetailsParameters() async {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.bankCollectorViewControllerToReturn = UIViewController()
        let scope = createScope()
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // When
        scope.submitUserDetails()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockInteractor.lastPatchedFirstName, AchTestData.Constants.firstName)
        XCTAssertEqual(mockInteractor.lastPatchedLastName, AchTestData.Constants.lastName)
        XCTAssertEqual(mockInteractor.lastPatchedEmailAddress, AchTestData.Constants.emailAddress)
    }

    @MainActor
    func test_submitUserDetails_callsStartPaymentAndGetStripeData() async {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.bankCollectorViewControllerToReturn = UIViewController()
        let scope = createScope()
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // When
        scope.submitUserDetails()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockInteractor.startPaymentAndGetStripeDataCallCount, 1)
    }

    @MainActor
    func test_submitUserDetails_callsCreateBankCollector() async {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.bankCollectorViewControllerToReturn = UIViewController()
        let scope = createScope()
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // When
        scope.submitUserDetails()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockInteractor.createBankCollectorCallCount, 1)
    }

    @MainActor
    func test_submitUserDetails_transitionsToBankAccountCollection() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.bankCollectorViewControllerToReturn = UIViewController()
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })

        // When
        scope.submitUserDetails()

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.step == .bankAccountCollection })
        XCTAssertEqual(state.step, .bankAccountCollection)
    }

    @MainActor
    func test_submitUserDetails_setsBankCollectorViewController() async throws {
        // Given
        let expectedVC = UIViewController()
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.bankCollectorViewControllerToReturn = expectedVC
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })

        // When
        scope.submitUserDetails()
        _ = try await awaitValue(scope.state, matching: { $0.step == .bankAccountCollection })

        // Then
        XCTAssertTrue(scope.bankCollectorViewController === expectedVC)
    }

    @MainActor
    func test_submitUserDetails_withInvalidUserDetails_doesNotCallPatch() async {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.emptyUserDetails
        let scope = createScope()
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // When
        scope.submitUserDetails()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockInteractor.patchUserDetailsCallCount, 0)
    }

    @MainActor
    func test_submit_callsSubmitUserDetails() async {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.bankCollectorViewControllerToReturn = UIViewController()
        let scope = createScope()
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // When
        scope.submit()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockInteractor.patchUserDetailsCallCount, 1)
    }

    // MARK: - Bank Collector Delegate Tests

    @MainActor
    func test_achBankCollectorDidSucceed_transitionsToMandateAcceptance() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.bankCollectorViewControllerToReturn = UIViewController()
        mockInteractor.mandateResultToReturn = AchTestData.fullMandateResult
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })
        scope.submitUserDetails()
        _ = try await awaitValue(scope.state, matching: { $0.step == .bankAccountCollection })

        // When
        scope.achBankCollectorDidSucceed(paymentId: AchTestData.Constants.paymentId)

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.step == .mandateAcceptance })
        XCTAssertEqual(state.step, .mandateAcceptance)
    }

    @MainActor
    func test_achBankCollectorDidSucceed_loadsMandateData() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.bankCollectorViewControllerToReturn = UIViewController()
        mockInteractor.mandateResultToReturn = AchTestData.fullMandateResult
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })
        scope.submitUserDetails()
        _ = try await awaitValue(scope.state, matching: { $0.step == .bankAccountCollection })

        // When
        scope.achBankCollectorDidSucceed(paymentId: AchTestData.Constants.paymentId)

        // Then
        _ = try await awaitValue(scope.state, matching: { $0.step == .mandateAcceptance })
        XCTAssertEqual(mockInteractor.getMandateDataCallCount, 1)
    }

    @MainActor
    func test_achBankCollectorDidSucceed_setsMandateText_fromFullText() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.bankCollectorViewControllerToReturn = UIViewController()
        mockInteractor.mandateResultToReturn = AchTestData.fullMandateResult
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })
        scope.submitUserDetails()
        _ = try await awaitValue(scope.state, matching: { $0.step == .bankAccountCollection })

        // When
        scope.achBankCollectorDidSucceed(paymentId: AchTestData.Constants.paymentId)

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.mandateText != nil })
        XCTAssertEqual(state.mandateText, AchTestData.Constants.mandateText)
    }

    @MainActor
    func test_achBankCollectorDidSucceed_setsMandateText_fromTemplate() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.bankCollectorViewControllerToReturn = UIViewController()
        mockInteractor.mandateResultToReturn = AchTestData.templateMandateResult
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })
        scope.submitUserDetails()
        _ = try await awaitValue(scope.state, matching: { $0.step == .bankAccountCollection })

        // When
        scope.achBankCollectorDidSucceed(paymentId: AchTestData.Constants.paymentId)

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.mandateText != nil })
        XCTAssertNotNil(state.mandateText)
        XCTAssertTrue(state.mandateText?.contains(AchTestData.Constants.merchantName) ?? false)
    }

    @MainActor
    func test_achBankCollectorDidCancel_doesNotCrash() {
        // Given
        let scope = createScope()

        // When/Then - should not crash
        scope.achBankCollectorDidCancel()
    }

    @MainActor
    func test_achBankCollectorDidCancel_clearsBankCollectorViewController() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.bankCollectorViewControllerToReturn = UIViewController()
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })
        scope.submitUserDetails()
        _ = try await awaitValue(scope.state, matching: { $0.step == .bankAccountCollection })
        XCTAssertNotNil(scope.bankCollectorViewController)

        // When
        scope.achBankCollectorDidCancel()

        // Then
        XCTAssertNil(scope.bankCollectorViewController)
    }

    @MainActor
    func test_achBankCollectorDidFail_doesNotCrash() {
        // Given
        let scope = createScope()
        let error = PrimerError.unknown(message: "Test error")

        // When/Then - should not crash
        scope.achBankCollectorDidFail(error: error)
    }

    @MainActor
    func test_achBankCollectorDidFail_clearsBankCollectorViewController() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.bankCollectorViewControllerToReturn = UIViewController()
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })
        scope.submitUserDetails()
        _ = try await awaitValue(scope.state, matching: { $0.step == .bankAccountCollection })
        XCTAssertNotNil(scope.bankCollectorViewController)

        // When
        scope.achBankCollectorDidFail(error: PrimerError.unknown(message: "Test"))

        // Then
        XCTAssertNil(scope.bankCollectorViewController)
    }

    // MARK: - Mandate Tests

    @MainActor
    func test_acceptMandate_transitionsToProcessing() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.bankCollectorViewControllerToReturn = UIViewController()
        mockInteractor.mandateResultToReturn = AchTestData.fullMandateResult
        mockInteractor.paymentResultToReturn = AchTestData.successPaymentResult
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })
        scope.submitUserDetails()
        _ = try await awaitValue(scope.state, matching: { $0.step == .bankAccountCollection })
        scope.achBankCollectorDidSucceed(paymentId: AchTestData.Constants.paymentId)
        _ = try await awaitValue(scope.state, matching: { $0.step == .mandateAcceptance })

        // When
        scope.acceptMandate()

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.step == .processing })
        XCTAssertEqual(state.step, .processing)
    }

    @MainActor
    func test_acceptMandate_callsCompletePayment() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.bankCollectorViewControllerToReturn = UIViewController()
        mockInteractor.mandateResultToReturn = AchTestData.fullMandateResult
        mockInteractor.paymentResultToReturn = AchTestData.successPaymentResult
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })
        scope.submitUserDetails()
        _ = try await awaitValue(scope.state, matching: { $0.step == .bankAccountCollection })
        scope.achBankCollectorDidSucceed(paymentId: AchTestData.Constants.paymentId)
        _ = try await awaitValue(scope.state, matching: { $0.step == .mandateAcceptance })

        // When
        scope.acceptMandate()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockInteractor.completePaymentCallCount, 1)
    }

    @MainActor
    func test_acceptMandate_whenNotInMandateAcceptance_doesNotComplete() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })

        // When
        scope.acceptMandate()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockInteractor.completePaymentCallCount, 0)
    }

    @MainActor
    func test_declineMandate_doesNotCrash() {
        // Given
        let scope = createScope()

        // When/Then - should not crash
        scope.declineMandate()
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
    func test_cancel_shouldNotCrash_viaCancel() {
        let scope = createScope()
        // Should not crash
        scope.cancel()
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
        let mechanism = scope.dismissalMechanism
        XCTAssertNotNil(mechanism)
    }

    // MARK: - State AsyncStream Tests

    @MainActor
    func test_state_emitsInitialState() async {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        let scope = createScope()

        // When
        var receivedStates: [PrimerAchState] = []
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

    // MARK: - Full Flow Integration Tests

    @MainActor
    func test_fullSuccessFlow_fromStartToPaymentComplete() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.bankCollectorViewControllerToReturn = UIViewController()
        mockInteractor.mandateResultToReturn = AchTestData.fullMandateResult
        mockInteractor.paymentResultToReturn = AchTestData.successPaymentResult
        let scope = createScope()

        // When - Start flow
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })

        // Submit user details
        scope.submitUserDetails()
        _ = try await awaitValue(scope.state, matching: { $0.step == .bankAccountCollection })

        // Bank collector succeeds
        scope.achBankCollectorDidSucceed(paymentId: AchTestData.Constants.paymentId)
        _ = try await awaitValue(scope.state, matching: { $0.step == .mandateAcceptance })

        // Accept mandate
        scope.acceptMandate()
        _ = try await awaitValue(scope.state, matching: { $0.step == .processing })

        // Wait for payment completion
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockInteractor.validateCallCount, 1)
        XCTAssertEqual(mockInteractor.loadUserDetailsCallCount, 1)
        XCTAssertEqual(mockInteractor.patchUserDetailsCallCount, 1)
        XCTAssertEqual(mockInteractor.startPaymentAndGetStripeDataCallCount, 1)
        XCTAssertEqual(mockInteractor.createBankCollectorCallCount, 1)
        XCTAssertEqual(mockInteractor.getMandateDataCallCount, 1)
        XCTAssertEqual(mockInteractor.completePaymentCallCount, 1)
    }

    // MARK: - Error Handling Tests

    @MainActor
    func test_start_validationFailure_doesNotCrash() async {
        // Given
        mockInteractor.validateError = TestError.networkFailure
        let scope = createScope()

        // When
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then - should not crash
        XCTAssertEqual(mockInteractor.validateCallCount, 1)
    }

    @MainActor
    func test_start_loadUserDetailsFailure_doesNotCrash() async {
        // Given
        mockInteractor.loadUserDetailsError = TestError.networkFailure
        let scope = createScope()

        // When
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then - should not crash
        XCTAssertEqual(mockInteractor.loadUserDetailsCallCount, 1)
    }

    @MainActor
    func test_submitUserDetails_patchFailure_doesNotCrash() async {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.patchUserDetailsError = TestError.networkFailure
        let scope = createScope()
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // When
        scope.submitUserDetails()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then - should not crash
        XCTAssertEqual(mockInteractor.patchUserDetailsCallCount, 1)
    }

    @MainActor
    func test_submitUserDetails_stripeDataFailure_doesNotCrash() async {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.startPaymentAndGetStripeDataError = TestError.networkFailure
        let scope = createScope()
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // When
        scope.submitUserDetails()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then - should not crash
        XCTAssertEqual(mockInteractor.startPaymentAndGetStripeDataCallCount, 1)
    }

    @MainActor
    func test_submitUserDetails_bankCollectorFailure_doesNotCrash() async {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.createBankCollectorError = TestError.networkFailure
        let scope = createScope()
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // When
        scope.submitUserDetails()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then - should not crash
        XCTAssertEqual(mockInteractor.createBankCollectorCallCount, 1)
    }

    @MainActor
    func test_achBankCollectorDidSucceed_mandateFailure_doesNotCrash() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.bankCollectorViewControllerToReturn = UIViewController()
        mockInteractor.getMandateDataError = TestError.networkFailure
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })
        scope.submitUserDetails()
        _ = try await awaitValue(scope.state, matching: { $0.step == .bankAccountCollection })

        // When
        scope.achBankCollectorDidSucceed(paymentId: AchTestData.Constants.paymentId)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then - should not crash
        XCTAssertEqual(mockInteractor.getMandateDataCallCount, 1)
    }

    @MainActor
    func test_acceptMandate_completePaymentFailure_doesNotCrash() async throws {
        // Given
        mockInteractor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockInteractor.stripeDataToReturn = AchTestData.defaultStripeData
        mockInteractor.bankCollectorViewControllerToReturn = UIViewController()
        mockInteractor.mandateResultToReturn = AchTestData.fullMandateResult
        mockInteractor.completePaymentError = TestError.networkFailure
        let scope = createScope()
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.step == .userDetailsCollection })
        scope.submitUserDetails()
        _ = try await awaitValue(scope.state, matching: { $0.step == .bankAccountCollection })
        scope.achBankCollectorDidSucceed(paymentId: AchTestData.Constants.paymentId)
        _ = try await awaitValue(scope.state, matching: { $0.step == .mandateAcceptance })

        // When
        scope.acceptMandate()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then - should not crash
        XCTAssertEqual(mockInteractor.completePaymentCallCount, 1)
    }

    // MARK: - Helper

    @MainActor
    private func createScope(
        presentationContext: PresentationContext = .fromPaymentSelection
    ) -> DefaultAchScope {
        let checkoutScope = DefaultCheckoutScope(
            clientToken: AchTestData.Constants.mockToken,
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )

        return DefaultAchScope(
            checkoutScope: checkoutScope,
            presentationContext: presentationContext,
            processAchInteractor: mockInteractor
        )
    }
}
