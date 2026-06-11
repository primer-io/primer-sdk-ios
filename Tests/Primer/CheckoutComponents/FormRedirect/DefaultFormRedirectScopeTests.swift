//
//  DefaultFormRedirectScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
final class DefaultFormRedirectScopeTests: XCTestCase {

    // MARK: - Properties

    private var mockInteractor: MockProcessFormRedirectPaymentInteractor!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
        mockInteractor = MockProcessFormRedirectPaymentInteractor()
    }

    override func tearDown() async throws {
        mockInteractor = nil
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    // MARK: - Field Configuration Tests

    @MainActor
    func test_init_blik_configuresOtpField() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)

        let state = try await awaitFirst(scope.state)
        XCTAssertEqual(state.fields.count, 1)
        XCTAssertEqual(state.fields.first?.fieldType, .otpCode)
        XCTAssertEqual(state.status, .ready)
    }

    @MainActor
    func test_init_mbway_configuresPhoneField() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.mbwayPaymentMethodType)

        let state = try await awaitFirst(scope.state)
        XCTAssertEqual(state.fields.count, 1)
        XCTAssertEqual(state.fields.first?.fieldType, .phoneNumber)
        XCTAssertEqual(state.status, .ready)
    }

    @MainActor
    func test_init_unsupportedPaymentMethod_setsFailureStatus() async throws {
        let scope = createScope(paymentMethodType: "UNSUPPORTED_TYPE")

        let state = try await awaitFirst(scope.state)
        if case .failure = state.status {
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

        scope.updateField(.otpCode, value: "123456")
        let stateAfterUpdate = try await awaitValue(scope.state, matching: { $0.fields.first?.value == "123456" })
        XCTAssertEqual(stateAfterUpdate.fields.first?.value, "123456")

        scope.start()

        let stateAfterSecondStart = try await awaitValue(scope.state, matching: { $0.fields.first?.value == "123456" })
        XCTAssertEqual(stateAfterSecondStart.fields.first?.value, "123456")
    }

    // MARK: - UpdateField Tests

    @MainActor
    func test_updateField_blik_filtersNonNumericCharacters() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()

        scope.updateField(.otpCode, value: "12ab34cd")

        let state = try await awaitValue(scope.state, matching: { $0.fields.first?.value == "1234" })
        XCTAssertEqual(state.fields.first?.value, "1234")
    }

    @MainActor
    func test_updateField_blik_truncatesTo6Characters() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()

        scope.updateField(.otpCode, value: "12345678")

        let state = try await awaitValue(scope.state, matching: { $0.fields.first?.value == "123456" })
        XCTAssertEqual(state.fields.first?.value, "123456")
    }

    @MainActor
    func test_updateField_blik_validCode_setsIsValidTrue() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()

        scope.updateField(.otpCode, value: "123456")

        let state = try await awaitValue(scope.state, matching: { $0.fields.first?.value == "123456" })
        XCTAssertTrue(state.fields.first?.isValid ?? false)
        XCTAssertNil(state.fields.first?.errorMessage)
    }

    @MainActor
    func test_updateField_blik_partialCode_invalidWithNoError() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()

        scope.updateField(.otpCode, value: "12345")

        let state = try await awaitValue(scope.state, matching: { $0.fields.first?.value == "12345" })
        XCTAssertFalse(state.fields.first?.isValid ?? true)
        XCTAssertNil(state.fields.first?.errorMessage)
    }

    @MainActor
    func test_updateField_blik_emptyValue_noErrorMessage() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()

        scope.updateField(.otpCode, value: "1")
        scope.updateField(.otpCode, value: "")

        let state = try await awaitValue(scope.state, matching: { $0.fields.first?.value == "" && $0.fields.first?.isValid == false })
        XCTAssertFalse(state.fields.first?.isValid ?? true)
        XCTAssertNil(state.fields.first?.errorMessage)
    }

    @MainActor
    func test_updateField_mbway_filtersNonNumericCharacters() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.mbwayPaymentMethodType)
        scope.start()

        scope.updateField(.phoneNumber, value: "912ab345cd678")

        let state = try await awaitValue(scope.state, matching: { $0.fields.first?.value == "912345678" })
        XCTAssertEqual(state.fields.first?.value, "912345678")
    }

    @MainActor
    func test_updateField_mbway_validPhone_setsIsValidTrue() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.mbwayPaymentMethodType)
        scope.start()

        scope.updateField(.phoneNumber, value: "912345678")

        let state = try await awaitValue(scope.state, matching: { $0.fields.first?.value == "912345678" })
        XCTAssertTrue(state.fields.first?.isValid ?? false)
    }

    @MainActor
    func test_updateField_mbway_shortPhone_setsIsValidFalse() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.mbwayPaymentMethodType)
        scope.start()

        scope.updateField(.phoneNumber, value: "123456")

        let state = try await awaitValue(scope.state, matching: { $0.fields.first?.value == "123456" })
        XCTAssertFalse(state.fields.first?.isValid ?? true)
    }

    @MainActor
    func test_updateField_nonExistentFieldType_isIgnored() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()

        // BLIK scope only has otpCode field, phoneNumber doesn't exist
        scope.updateField(.phoneNumber, value: "912345678")

        // The ignored update yields no state change, so assert on the unchanged initial state
        let state = try await awaitFirst(scope.state)
        XCTAssertEqual(state.fields.count, 1)
        XCTAssertEqual(state.fields.first?.fieldType, .otpCode)
        XCTAssertEqual(state.fields.first?.value, "")
    }

    // MARK: - Submit Tests

    @MainActor
    func test_submit_withInvalidForm_doesNotCallInteractor() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        scope.updateField(.otpCode, value: "12345")
        // Ensure the field update has been applied before submitting
        _ = try await awaitValue(scope.state, matching: { $0.fields.first?.value == "12345" })

        scope.submit()
        // why: invalid form short-circuits submit synchronously; there is no signal to await, so
        // tick once to confirm the interactor is never invoked
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mockInteractor.executeCallCount, 0)
    }

    @MainActor
    func test_submit_withValidForm_callsInteractor() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        scope.updateField(.otpCode, value: "123456")
        _ = try await awaitValue(scope.state, matching: { $0.isSubmitEnabled })

        scope.submit()
        try await withTimeout(2.0) { [self] in
            while mockInteractor.executeCallCount == 0 { await Task.yield() }
        }

        XCTAssertEqual(mockInteractor.executeCallCount, 1)
    }

    @MainActor
    func test_submit_blik_passesCorrectSessionInfo() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        scope.updateField(.otpCode, value: FormRedirectTestData.Constants.validBlikCode)
        _ = try await awaitValue(scope.state, matching: { $0.isSubmitEnabled })

        scope.submit()
        try await withTimeout(2.0) { [self] in
            while mockInteractor.executeSessionInfo == nil { await Task.yield() }
        }

        XCTAssertTrue(mockInteractor.executeSessionInfo is BlikSessionInfo)
        if let sessionInfo = mockInteractor.executeSessionInfo as? BlikSessionInfo {
            XCTAssertEqual(sessionInfo.blikCode, FormRedirectTestData.Constants.validBlikCode)
        }
    }

    @MainActor
    func test_submit_mbway_passesCorrectSessionInfo() async throws {
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.mbwayPaymentMethodType)
        scope.start()
        scope.updateField(.phoneNumber, value: FormRedirectTestData.Constants.validPhoneNumber)
        _ = try await awaitValue(scope.state, matching: { $0.isSubmitEnabled })

        scope.submit()
        try await withTimeout(2.0) { [self] in
            while mockInteractor.executeSessionInfo == nil { await Task.yield() }
        }

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
        scope.updateField(.otpCode, value: "123456")
        _ = try await awaitValue(scope.state, matching: { $0.isSubmitEnabled })

        scope.submit()

        let state = try await awaitValue(scope.state, matching: { $0.status == .success })
        XCTAssertEqual(state.status, .success)
    }

    @MainActor
    func test_submit_failure_transitionsToFailureStatus() async throws {
        mockInteractor.executeResult = .failure(PrimerError.unknown(message: "Payment failed"))
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        scope.updateField(.otpCode, value: "123456")
        _ = try await awaitValue(scope.state, matching: { $0.isSubmitEnabled })

        scope.submit()

        let state = try await awaitValue(scope.state, matching: {
            if case .failure = $0.status { true } else { false }
        })
        if case .failure = state.status {
            // Expected
        } else {
            XCTFail("Expected failure status after payment error")
        }
    }

    @MainActor
    func test_submit_cancelledError_doesNotTransitionToFailure() async throws {
        mockInteractor.executeResult = .failure(
            PrimerError.cancelled(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        )
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        scope.updateField(.otpCode, value: "123456")
        _ = try await awaitValue(scope.state, matching: { $0.isSubmitEnabled })

        scope.submit()
        // Cancellation returns without a terminal state, so await the interactor call as the signal
        try await withTimeout(2.0) { [self] in
            while mockInteractor.executeCallCount == 0 { await Task.yield() }
        }

        // Cancellation is a clean dismissal, never surfaced as a payment failure
        let state = try await awaitFirst(scope.state)
        if case .failure = state.status {
            XCTFail("Cancellation must not transition to failure")
        }
        XCTAssertEqual(mockInteractor.executeCallCount, 1)
    }

    @MainActor
    func test_submit_pollingStarted_transitionsToAwaitingExternalCompletion() async throws {
        mockInteractor.shouldCallOnPollingStarted = true
        mockInteractor.executeDelay = 0.6
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        scope.updateField(.otpCode, value: "123456")
        _ = try await awaitValue(scope.state, matching: { $0.isSubmitEnabled })

        scope.submit()

        let state = try await awaitValue(scope.state, matching: { $0.status == .awaitingExternalCompletion })
        XCTAssertEqual(state.status, .awaitingExternalCompletion)
    }

    // MARK: - Cancel Tests

    @MainActor
    func test_cancel_cancelsPolling() async throws {
        mockInteractor.executeDelay = 1.0
        let scope = createScope(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)
        scope.start()
        scope.updateField(.otpCode, value: "123456")
        _ = try await awaitValue(scope.state, matching: { $0.isSubmitEnabled })

        scope.submit()
        // Wait until execute is in-flight before cancelling
        try await withTimeout(2.0) { [self] in
            while mockInteractor.executeCallCount == 0 { await Task.yield() }
        }

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

    // MARK: - Unsupported Payment Method Tests

    @MainActor
    func test_buildSessionInfo_unsupportedType_throwsError() async throws {
        let scope = createScope(paymentMethodType: "UNSUPPORTED_TYPE")
        scope.start()

        scope.submit()

        // Unsupported type fails configuration in init, so submit short-circuits and never calls execute
        let state = try await awaitValue(scope.state, matching: {
            if case .failure = $0.status { true } else { false }
        })
        if case .failure = state.status {
            // Expected
        } else {
            XCTFail("Expected failure status for unsupported payment method type")
        }
        XCTAssertEqual(mockInteractor.executeCallCount, 0)
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
}
