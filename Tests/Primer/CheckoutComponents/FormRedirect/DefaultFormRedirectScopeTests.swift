//
//  DefaultFormRedirectScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
final class DefaultFormRedirectScopeTests: XCTestCase {

    // MARK: - Properties

    private var mockInteractor: MockProcessFormRedirectPaymentInteractor!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockInteractor = MockProcessFormRedirectPaymentInteractor()
    }

    override func tearDown() {
        mockInteractor = nil
        super.tearDown()
    }

    // MARK: - Field Configuration Tests

    @MainActor
    func test_init_blik_configuresOtpField() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)

        let state = await collectFirstState(from: scope)
        XCTAssertEqual(state?.fields.count, 1)
        XCTAssertEqual(state?.fields.first?.fieldType, .otpCode)
        XCTAssertEqual(state?.status, .ready)
    }

    @MainActor
    func test_init_mbway_configuresPhoneField() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.mbwayPaymentMethodType)

        let state = await collectFirstState(from: scope)
        XCTAssertEqual(state?.fields.count, 1)
        XCTAssertEqual(state?.fields.first?.fieldType, .phoneNumber)
        XCTAssertEqual(state?.status, .ready)
    }

    @MainActor
    func test_init_unsupportedPaymentMethod_setsFailureStatus() async throws {
        let scope = createScope(paymentMethodType: "UNSUPPORTED_TYPE")

        let state = await collectFirstState(from: scope)
        if case .failure = state?.status {
            // Expected
        } else {
            XCTFail("Expected failure status for unsupported payment method")
        }
    }

    // MARK: - Start Tests

    @MainActor
    func test_start_calledTwice_doesNotResetState() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        try await Task.sleep(nanoseconds: 50_000_000)

        scope.updateField(.otpCode, value: "123456")
        let stateAfterUpdate = await collectFirstState(from: scope)
        XCTAssertEqual(stateAfterUpdate?.fields.first?.value, "123456")

        scope.start()

        let stateAfterSecondStart = await collectFirstState(from: scope)
        XCTAssertEqual(stateAfterSecondStart?.fields.first?.value, "123456")
    }

    // MARK: - UpdateField Tests

    @MainActor
    func test_updateField_blik_filtersNonNumericCharacters() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        try await Task.sleep(nanoseconds: 50_000_000)

        scope.updateField(.otpCode, value: "12ab34cd")

        let state = await collectFirstState(from: scope)
        XCTAssertEqual(state?.fields.first?.value, "1234")
    }

    @MainActor
    func test_updateField_blik_truncatesTo6Characters() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        try await Task.sleep(nanoseconds: 50_000_000)

        scope.updateField(.otpCode, value: "12345678")

        let state = await collectFirstState(from: scope)
        XCTAssertEqual(state?.fields.first?.value, "123456")
    }

    @MainActor
    func test_updateField_blik_validCode_setsIsValidTrue() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        try await Task.sleep(nanoseconds: 50_000_000)

        scope.updateField(.otpCode, value: "123456")

        let state = await collectFirstState(from: scope)
        XCTAssertTrue(state?.fields.first?.isValid ?? false)
        XCTAssertNil(state?.fields.first?.errorMessage)
    }

    @MainActor
    func test_updateField_blik_partialCode_invalidWithNoError() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        try await Task.sleep(nanoseconds: 50_000_000)

        scope.updateField(.otpCode, value: "12345")

        let state = await collectFirstState(from: scope)
        XCTAssertFalse(state?.fields.first?.isValid ?? true)
        XCTAssertNil(state?.fields.first?.errorMessage)
    }

    @MainActor
    func test_updateField_blik_emptyValue_noErrorMessage() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        try await Task.sleep(nanoseconds: 50_000_000)

        scope.updateField(.otpCode, value: "")

        let state = await collectFirstState(from: scope)
        XCTAssertFalse(state?.fields.first?.isValid ?? true)
        XCTAssertNil(state?.fields.first?.errorMessage)
    }

    @MainActor
    func test_updateField_mbway_filtersNonNumericCharacters() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.mbwayPaymentMethodType)
        scope.start()
        try await Task.sleep(nanoseconds: 50_000_000)

        scope.updateField(.phoneNumber, value: "912ab345cd678")

        let state = await collectFirstState(from: scope)
        XCTAssertEqual(state?.fields.first?.value, "912345678")
    }

    @MainActor
    func test_updateField_mbway_validPhone_setsIsValidTrue() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.mbwayPaymentMethodType)
        scope.start()
        try await Task.sleep(nanoseconds: 50_000_000)

        scope.updateField(.phoneNumber, value: "912345678")

        let state = await collectFirstState(from: scope)
        XCTAssertTrue(state?.fields.first?.isValid ?? false)
    }

    @MainActor
    func test_updateField_mbway_shortPhone_setsIsValidFalse() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.mbwayPaymentMethodType)
        scope.start()
        try await Task.sleep(nanoseconds: 50_000_000)

        scope.updateField(.phoneNumber, value: "123456")

        let state = await collectFirstState(from: scope)
        XCTAssertFalse(state?.fields.first?.isValid ?? true)
    }

    @MainActor
    func test_updateField_nonExistentFieldType_isIgnored() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        try await Task.sleep(nanoseconds: 50_000_000)

        // BLIK scope only has otpCode field, phoneNumber doesn't exist
        scope.updateField(.phoneNumber, value: "912345678")

        let state = await collectFirstState(from: scope)
        XCTAssertEqual(state?.fields.count, 1)
        XCTAssertEqual(state?.fields.first?.fieldType, .otpCode)
        XCTAssertEqual(state?.fields.first?.value, "")
    }

    // MARK: - Submit Tests

    @MainActor
    func test_submit_withInvalidForm_doesNotCallInteractor() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        try await Task.sleep(nanoseconds: 50_000_000)
        scope.updateField(.otpCode, value: "12345")

        scope.submit()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mockInteractor.executeCallCount, 0)
    }

    @MainActor
    func test_submit_withValidForm_callsInteractor() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        try await Task.sleep(nanoseconds: 50_000_000)
        scope.updateField(.otpCode, value: "123456")
        try await Task.sleep(nanoseconds: 50_000_000)

        scope.submit()
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(mockInteractor.executeCallCount, 1)
    }

    @MainActor
    func test_submit_blik_passesCorrectSessionInfo() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        try await Task.sleep(nanoseconds: 50_000_000)
        scope.updateField(.otpCode, value: FormRedirectTestData.Constants.validBlikCode)
        try await Task.sleep(nanoseconds: 50_000_000)

        scope.submit()
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertTrue(mockInteractor.executeSessionInfo is BlikSessionInfo)
        if let sessionInfo = mockInteractor.executeSessionInfo as? BlikSessionInfo {
            XCTAssertEqual(sessionInfo.blikCode, FormRedirectTestData.Constants.validBlikCode)
        }
    }

    @MainActor
    func test_submit_mbway_passesCorrectSessionInfo() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.mbwayPaymentMethodType)
        scope.start()
        try await Task.sleep(nanoseconds: 50_000_000)
        scope.updateField(.phoneNumber, value: FormRedirectTestData.Constants.validPhoneNumber)
        try await Task.sleep(nanoseconds: 50_000_000)

        scope.submit()
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertTrue(mockInteractor.executeSessionInfo is InputPhonenumberSessionInfo)
        if let sessionInfo = mockInteractor.executeSessionInfo as? InputPhonenumberSessionInfo {
            XCTAssertTrue(sessionInfo.phoneNumber.hasSuffix(FormRedirectTestData.Constants.validPhoneNumber))
        }
    }

    // MARK: - Submit State Transition Tests

    @MainActor
    func test_submit_success_transitionsToSuccessStatus() async throws {
        mockInteractor.executeResult = .success(FormRedirectTestData.successPaymentResult)
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        try await Task.sleep(nanoseconds: 50_000_000)
        scope.updateField(.otpCode, value: "123456")
        try await Task.sleep(nanoseconds: 50_000_000)

        scope.submit()
        try await Task.sleep(nanoseconds: 300_000_000)

        let state = await collectFirstState(from: scope)
        XCTAssertEqual(state?.status, .success)
    }

    @MainActor
    func test_submit_failure_transitionsToFailureStatus() async throws {
        mockInteractor.executeResult = .failure(PrimerError.unknown(message: "Payment failed"))
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        try await Task.sleep(nanoseconds: 50_000_000)
        scope.updateField(.otpCode, value: "123456")
        try await Task.sleep(nanoseconds: 50_000_000)

        scope.submit()
        try await Task.sleep(nanoseconds: 300_000_000)

        let state = await collectFirstState(from: scope)
        if case .failure = state?.status {
            // Expected
        } else {
            XCTFail("Expected failure status after payment error")
        }
    }

    @MainActor
    func test_submit_pollingStarted_transitionsToAwaitingExternalCompletion() async throws {
        mockInteractor.shouldCallOnPollingStarted = true
        mockInteractor.executeDelay = 0.3
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        try await Task.sleep(nanoseconds: 50_000_000)
        scope.updateField(.otpCode, value: "123456")
        try await Task.sleep(nanoseconds: 50_000_000)

        scope.submit()
        // Wait enough for onPollingStarted to fire but not for the full execute to complete
        try await Task.sleep(nanoseconds: 200_000_000)

        let state = await collectFirstState(from: scope)
        XCTAssertEqual(state?.status, .awaitingExternalCompletion)
    }

    // MARK: - Cancel Tests

    @MainActor
    func test_cancel_cancelsPolling() async throws {
        mockInteractor.executeDelay = 1.0
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        try await Task.sleep(nanoseconds: 50_000_000)
        scope.updateField(.otpCode, value: "123456")
        try await Task.sleep(nanoseconds: 50_000_000)

        scope.submit()
        try await Task.sleep(nanoseconds: 100_000_000)

        scope.cancel()

        XCTAssertEqual(mockInteractor.cancelPollingCallCount, 1)
        XCTAssertEqual(
            mockInteractor.cancelPollingPaymentMethodType,
            FormRedirectTestData.Constants.blikPaymentMethodType
        )
    }

    // MARK: - Navigation Tests

    @MainActor
    func test_onBack_navigatesBackToPaymentSelection() {
        let coordinator = CheckoutCoordinator()
        coordinator.navigate(to: .paymentMethodSelection)
        coordinator.navigate(
            to: .paymentMethod(FormRedirectTestData.Constants.blikPaymentMethodType, .fromPaymentSelection)
        )
        let navigator = CheckoutNavigator(coordinator: coordinator)
        let settings = PrimerSettings(
            paymentHandling: .manual,
            paymentMethodOptions: PrimerPaymentMethodOptions()
        )
        let checkoutScope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: settings,
            diContainer: DIContainer.shared,
            navigator: navigator,
            presentationContext: .fromPaymentSelection
        )
        let scope = DefaultFormRedirectScope(
            paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
            checkoutScope: checkoutScope,
            presentationContext: .fromPaymentSelection,
            processPaymentInteractor: mockInteractor,
            validationService: DefaultValidationService()
        )

        scope.onBack()

        XCTAssertEqual(coordinator.navigationStack.count, 1)
        XCTAssertEqual(coordinator.currentRoute, .paymentMethodSelection)
    }

    // MARK: - Helper Methods

    @MainActor
    private func createScope(
        paymentMethodType: String = FormRedirectTestData.Constants.blikPaymentMethodType,
        presentationContext: PresentationContext = .fromPaymentSelection
    ) -> DefaultFormRedirectScope {
        DefaultFormRedirectScope(
            paymentMethodType: paymentMethodType,
            presentationContext: presentationContext,
            processPaymentInteractor: mockInteractor
        )
    }

    @MainActor
    private func collectFirstState(from scope: DefaultFormRedirectScope) async -> FormRedirectState? {
        var collectedState: FormRedirectState?
        let task = Task {
            for await state in scope.state {
                collectedState = state
                break
            }
        }
        try? await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()
        return collectedState
    }
}
