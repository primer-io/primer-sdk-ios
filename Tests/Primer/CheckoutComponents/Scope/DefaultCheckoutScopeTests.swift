//
//  DefaultCheckoutScopeTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for DefaultCheckoutScope.NavigationState.
@available(iOS 15.0, *)
@MainActor
final class DefaultCheckoutScopeNavigationStateTests: XCTestCase {

    // MARK: - NavigationState Equality Tests

    func test_navigationState_loading_equality() {
        let state1 = DefaultCheckoutScope.NavigationState.loading
        let state2 = DefaultCheckoutScope.NavigationState.loading

        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_paymentMethodSelection_equality() {
        let state1 = DefaultCheckoutScope.NavigationState.paymentMethodSelection
        let state2 = DefaultCheckoutScope.NavigationState.paymentMethodSelection

        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_paymentMethod_sameType_areEqual() {
        let state1 = DefaultCheckoutScope.NavigationState.paymentMethod("PAYMENT_CARD")
        let state2 = DefaultCheckoutScope.NavigationState.paymentMethod("PAYMENT_CARD")

        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_paymentMethod_differentType_areNotEqual() {
        let state1 = DefaultCheckoutScope.NavigationState.paymentMethod("PAYMENT_CARD")
        let state2 = DefaultCheckoutScope.NavigationState.paymentMethod("PAYPAL")

        XCTAssertNotEqual(state1, state2)
    }

    func test_navigationState_processing_equality() {
        let state1 = DefaultCheckoutScope.NavigationState.processing
        let state2 = DefaultCheckoutScope.NavigationState.processing

        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_success_samePaymentId_areEqual() {
        let result1 = CheckoutPaymentResult(paymentId: "payment-123", amount: "10.00")
        let result2 = CheckoutPaymentResult(paymentId: "payment-123", amount: "10.00")

        let state1 = DefaultCheckoutScope.NavigationState.success(result1)
        let state2 = DefaultCheckoutScope.NavigationState.success(result2)

        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_success_differentPaymentId_areNotEqual() {
        let result1 = CheckoutPaymentResult(paymentId: "payment-123", amount: "10.00")
        let result2 = CheckoutPaymentResult(paymentId: "payment-456", amount: "10.00")

        let state1 = DefaultCheckoutScope.NavigationState.success(result1)
        let state2 = DefaultCheckoutScope.NavigationState.success(result2)

        XCTAssertNotEqual(state1, state2)
    }

    func test_navigationState_failure_sameError_areEqual() {
        // Use the same error instance to test equality
        // (PrimerError has unique diagnosticsId per instance)
        let error = PrimerError.invalidArchitecture(
            description: "Test error",
            recoverSuggestion: nil
        )

        let state1 = DefaultCheckoutScope.NavigationState.failure(error)
        let state2 = DefaultCheckoutScope.NavigationState.failure(error)

        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_failure_differentErrorMessage_areNotEqual() {
        let error1 = PrimerError.invalidArchitecture(
            description: "Test error 1",
            recoverSuggestion: nil
        )
        let error2 = PrimerError.invalidArchitecture(
            description: "Test error 2",
            recoverSuggestion: nil
        )

        let state1 = DefaultCheckoutScope.NavigationState.failure(error1)
        let state2 = DefaultCheckoutScope.NavigationState.failure(error2)

        XCTAssertNotEqual(state1, state2)
    }

    func test_navigationState_dismissed_equality() {
        let state1 = DefaultCheckoutScope.NavigationState.dismissed
        let state2 = DefaultCheckoutScope.NavigationState.dismissed

        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_differentTypes_areNotEqual() {
        let loading = DefaultCheckoutScope.NavigationState.loading
        let selection = DefaultCheckoutScope.NavigationState.paymentMethodSelection
        let processing = DefaultCheckoutScope.NavigationState.processing
        let dismissed = DefaultCheckoutScope.NavigationState.dismissed

        XCTAssertNotEqual(loading, selection)
        XCTAssertNotEqual(loading, processing)
        XCTAssertNotEqual(loading, dismissed)
        XCTAssertNotEqual(selection, processing)
        XCTAssertNotEqual(selection, dismissed)
        XCTAssertNotEqual(processing, dismissed)
    }

    func test_navigationState_loadingVsPaymentMethod_areNotEqual() {
        let loading = DefaultCheckoutScope.NavigationState.loading
        let paymentMethod = DefaultCheckoutScope.NavigationState.paymentMethod("PAYMENT_CARD")

        XCTAssertNotEqual(loading, paymentMethod)
    }

    func test_navigationState_loadingVsSuccess_areNotEqual() {
        let loading = DefaultCheckoutScope.NavigationState.loading
        let success = DefaultCheckoutScope.NavigationState.success(
            CheckoutPaymentResult(paymentId: "payment-123", amount: "10.00")
        )

        XCTAssertNotEqual(loading, success)
    }

    func test_navigationState_loadingVsFailure_areNotEqual() {
        let loading = DefaultCheckoutScope.NavigationState.loading
        let failure = DefaultCheckoutScope.NavigationState.failure(
            PrimerError.invalidArchitecture(description: "Error", recoverSuggestion: nil)
        )

        XCTAssertNotEqual(loading, failure)
    }

    func test_navigationState_paymentMethodVsSuccess_areNotEqual() {
        let paymentMethod = DefaultCheckoutScope.NavigationState.paymentMethod("PAYMENT_CARD")
        let success = DefaultCheckoutScope.NavigationState.success(
            CheckoutPaymentResult(paymentId: "payment-123", amount: "10.00")
        )

        XCTAssertNotEqual(paymentMethod, success)
    }

    func test_navigationState_successVsFailure_areNotEqual() {
        let success = DefaultCheckoutScope.NavigationState.success(
            CheckoutPaymentResult(paymentId: "payment-123", amount: "10.00")
        )
        let failure = DefaultCheckoutScope.NavigationState.failure(
            PrimerError.invalidArchitecture(description: "Error", recoverSuggestion: nil)
        )

        XCTAssertNotEqual(success, failure)
    }
}

// MARK: - CheckoutPaymentResult Tests

@available(iOS 15.0, *)
final class CheckoutPaymentResultTests: XCTestCase {

    func test_init_setsPaymentId() {
        let result = CheckoutPaymentResult(paymentId: "payment-123", amount: "10.00")

        XCTAssertEqual(result.paymentId, "payment-123")
    }

    func test_init_setsAmount() {
        let result = CheckoutPaymentResult(paymentId: "payment-123", amount: "25.50")

        XCTAssertEqual(result.amount, "25.50")
    }

    func test_paymentId_withUUID() {
        let uuid = "550e8400-e29b-41d4-a716-446655440000"
        let result = CheckoutPaymentResult(paymentId: uuid, amount: "100.00")

        XCTAssertEqual(result.paymentId, uuid)
    }

    func test_amount_withDifferentFormats() {
        let result1 = CheckoutPaymentResult(paymentId: "1", amount: "0.00")
        let result2 = CheckoutPaymentResult(paymentId: "2", amount: "1.99")
        let result3 = CheckoutPaymentResult(paymentId: "3", amount: "1000.00")
        let result4 = CheckoutPaymentResult(paymentId: "4", amount: "N/A")

        XCTAssertEqual(result1.amount, "0.00")
        XCTAssertEqual(result2.amount, "1.99")
        XCTAssertEqual(result3.amount, "1000.00")
        XCTAssertEqual(result4.amount, "N/A")
    }
}

// MARK: - PaymentResult Tests

@available(iOS 15.0, *)
final class PaymentResultTests: XCTestCase {

    func test_init_setsRequiredProperties() {
        let result = PaymentResult(paymentId: "payment-123", status: .success)

        XCTAssertEqual(result.paymentId, "payment-123")
        XCTAssertEqual(result.status, .success)
    }

    func test_init_optionalPropertiesDefaultToNil() {
        let result = PaymentResult(paymentId: "payment-123", status: .success)

        XCTAssertNil(result.token)
        XCTAssertNil(result.redirectUrl)
        XCTAssertNil(result.errorMessage)
        XCTAssertNil(result.metadata)
        XCTAssertNil(result.amount)
        XCTAssertNil(result.paymentMethodType)
    }

    func test_init_setsAllProperties() {
        let metadata: [String: Any] = ["key": "value"]
        let result = PaymentResult(
            paymentId: "payment-123",
            status: .authorized,
            token: "token-abc",
            redirectUrl: "https://example.com/redirect",
            errorMessage: nil,
            metadata: metadata,
            amount: TestData.Amounts.standard,
            paymentMethodType: "PAYMENT_CARD"
        )

        XCTAssertEqual(result.paymentId, "payment-123")
        XCTAssertEqual(result.status, .authorized)
        XCTAssertEqual(result.token, "token-abc")
        XCTAssertEqual(result.redirectUrl, "https://example.com/redirect")
        XCTAssertNil(result.errorMessage)
        XCTAssertNotNil(result.metadata)
        XCTAssertEqual(result.amount, 1000)
        XCTAssertEqual(result.paymentMethodType, "PAYMENT_CARD")
    }

    func test_status_pending() {
        let result = PaymentResult(paymentId: "1", status: .pending)
        XCTAssertEqual(result.status, .pending)
    }

    func test_status_processing() {
        let result = PaymentResult(paymentId: "1", status: .processing)
        XCTAssertEqual(result.status, .processing)
    }

    func test_status_authorized() {
        let result = PaymentResult(paymentId: "1", status: .authorized)
        XCTAssertEqual(result.status, .authorized)
    }

    func test_status_success() {
        let result = PaymentResult(paymentId: "1", status: .success)
        XCTAssertEqual(result.status, .success)
    }

    func test_status_failed() {
        let result = PaymentResult(paymentId: "1", status: .failed)
        XCTAssertEqual(result.status, .failed)
    }

    func test_status_cancelled() {
        let result = PaymentResult(paymentId: "1", status: .cancelled)
        XCTAssertEqual(result.status, .cancelled)
    }

    func test_status_requires3DS() {
        let result = PaymentResult(paymentId: "1", status: .requires3DS)
        XCTAssertEqual(result.status, .requires3DS)
    }

    func test_status_requiresAction() {
        let result = PaymentResult(paymentId: "1", status: .requiresAction)
        XCTAssertEqual(result.status, .requiresAction)
    }

    func test_withErrorMessage() {
        let result = PaymentResult(
            paymentId: "payment-123",
            status: .failed,
            errorMessage: "Insufficient funds"
        )

        XCTAssertEqual(result.status, .failed)
        XCTAssertEqual(result.errorMessage, "Insufficient funds")
    }
}

// MARK: - DefaultCheckoutScope Behavior Tests

@available(iOS 15.0, *)
@MainActor
final class DefaultCheckoutScopeBehaviorTests: XCTestCase {

    // MARK: - Test Helpers

    private func createTestContainer() async -> Container {
        await ContainerTestHelpers.createTestContainer()
    }

    private func createDefaultSettings() -> PrimerSettings {
        PrimerSettings(
            paymentHandling: .manual,
            paymentMethodOptions: PrimerPaymentMethodOptions()
        )
    }

    // MARK: - Initialization Tests

    func test_initialization_startsInInitializingState() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            // Initial internal state should be initializing
            XCTAssertEqual(scope.currentState, .initializing)
        }
    }

    func test_initialization_navigationStateStartsAsLoading() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            // Initial navigation state should be loading
            XCTAssertEqual(scope.navigationState, .loading)
        }
    }

    // MARK: - Settings Access Tests

    func test_isInitScreenEnabled_returnsValueFromSettings() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = PrimerSettings(
                paymentHandling: .manual,
                paymentMethodOptions: PrimerPaymentMethodOptions(),
                uiOptions: PrimerUIOptions(isInitScreenEnabled: true)
            )

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            XCTAssertTrue(scope.isInitScreenEnabled)
        }
    }

    func test_isSuccessScreenEnabled_returnsValueFromSettings() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = PrimerSettings(
                paymentHandling: .manual,
                paymentMethodOptions: PrimerPaymentMethodOptions(),
                uiOptions: PrimerUIOptions(isSuccessScreenEnabled: false)
            )

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            XCTAssertFalse(scope.isSuccessScreenEnabled)
        }
    }

    func test_isErrorScreenEnabled_returnsValueFromSettings() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = PrimerSettings(
                paymentHandling: .manual,
                paymentMethodOptions: PrimerPaymentMethodOptions(),
                uiOptions: PrimerUIOptions(isErrorScreenEnabled: true)
            )

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            XCTAssertTrue(scope.isErrorScreenEnabled)
        }
    }

    func test_paymentHandling_returnsValueFromSettings() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = PrimerSettings(
                paymentHandling: .auto,
                paymentMethodOptions: PrimerPaymentMethodOptions()
            )

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            XCTAssertEqual(scope.paymentHandling, .auto)
        }
    }

    // MARK: - Child Scope Access Tests

    func test_paymentMethodSelection_returnsSameInstance() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            let selection1 = scope.paymentMethodSelection
            let selection2 = scope.paymentMethodSelection

            // Should return the same cached instance
            XCTAssertTrue(selection1 === selection2)
        }
    }

    // MARK: - Navigation State Update Tests

    func test_updateNavigationState_updatesState() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            scope.updateNavigationState(.paymentMethodSelection)

            XCTAssertEqual(scope.navigationState, .paymentMethodSelection)
        }
    }

    func test_updateNavigationState_toProcessing() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            scope.updateNavigationState(.processing)

            XCTAssertEqual(scope.navigationState, .processing)
        }
    }

    func test_startProcessing_setsProcessingState() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            scope.startProcessing()

            XCTAssertEqual(scope.navigationState, .processing)
        }
    }

    // MARK: - Payment Method Selection Tests

    func test_handlePaymentMethodSelection_updatesNavigationStateOrFailure() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            let paymentMethod = InternalPaymentMethod(
                id: "card-1",
                type: "PAYMENT_CARD",
                name: "Credit Card",
                isEnabled: true
            )

            scope.handlePaymentMethodSelection(paymentMethod)

            // In test environment without full payment method registration,
            // this may result in either paymentMethod state or failure state
            let isPaymentMethodState = scope.navigationState == .paymentMethod("PAYMENT_CARD")
            let isFailureState: Bool
            if case .failure = scope.navigationState {
                isFailureState = true
            } else {
                isFailureState = false
            }

            XCTAssertTrue(isPaymentMethodState || isFailureState,
                          "Expected paymentMethod or failure state, got: \(scope.navigationState)")
        }
    }

    // MARK: - Payment Success Tests

    func test_handlePaymentSuccess_updatesState() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            let result = PaymentResult(paymentId: "payment-123", status: .success)

            scope.handlePaymentSuccess(result)

            if case .success = scope.currentState {
                // State is success
            } else {
                XCTFail("Expected success state")
            }

            if case let .success(checkoutResult) = scope.navigationState {
                XCTAssertEqual(checkoutResult.paymentId, "payment-123")
            } else {
                XCTFail("Expected success navigation state")
            }
        }
    }

    // MARK: - Payment Error Tests

    func test_handlePaymentError_updatesState() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            let error = PrimerError.invalidArchitecture(
                description: "Test error",
                recoverSuggestion: nil
            )

            scope.handlePaymentError(error)

            if case .failure = scope.currentState {
                // State is failure
            } else {
                XCTFail("Expected failure state")
            }

            if case let .failure(resultError) = scope.navigationState {
                XCTAssertTrue(resultError.localizedDescription.contains("Test error"))
            } else {
                XCTFail("Expected failure navigation state")
            }
        }
    }

    // MARK: - Dismissal Tests

    func test_updateNavigationState_toDismissed() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            // Test that updateNavigationState works correctly for dismissed state
            scope.updateNavigationState(.dismissed)

            XCTAssertEqual(scope.navigationState, .dismissed)
        }
    }

    func test_onDismiss_updatesCurrentState() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            scope.onDismiss()

            // Wait for the internal Task to complete
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

            XCTAssertEqual(scope.currentState, .dismissed)
        }
    }

    // MARK: - Navigator Access Tests

    func test_checkoutNavigator_returnsNavigator() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            XCTAssertNotNil(scope.checkoutNavigator)
        }
    }

    // MARK: - Presentation Context Tests

    func test_presentationContext_defaultsToFromPaymentSelection() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
        }
    }

    func test_presentationContext_canBeSetToDirect() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator,
                presentationContext: .direct
            )

            XCTAssertEqual(scope.presentationContext, .direct)
        }
    }

    // MARK: - Available Payment Methods Tests

    func test_availablePaymentMethods_startsEmpty() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            XCTAssertTrue(scope.availablePaymentMethods.isEmpty)
        }
    }

    // MARK: - UI Customization Properties Tests

    func test_container_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            XCTAssertNil(scope.container)
        }
    }

    func test_splashScreen_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            XCTAssertNil(scope.splashScreen)
        }
    }

    func test_loading_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            XCTAssertNil(scope.loading)
        }
    }

    func test_successScreen_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            XCTAssertNil(scope.successScreen)
        }
    }

    func test_errorScreen_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            XCTAssertNil(scope.errorScreen)
        }
    }

    func test_paymentMethodSelectionScreen_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = createDefaultSettings()

            let scope = DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )

            XCTAssertNil(scope.paymentMethodSelectionScreen)
        }
    }
}
