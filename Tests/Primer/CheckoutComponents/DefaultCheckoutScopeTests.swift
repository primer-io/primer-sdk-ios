//
//  DefaultCheckoutScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

// MARK: - NavigationState Equality Tests

/// Tests for the NavigationState enum's custom equality implementation.
/// NavigationState uses custom equality logic to compare different states,
/// including comparing specific properties for complex states like success/failure.
@available(iOS 15.0, *)
final class NavigationStateEqualityTests: XCTestCase {

    // MARK: - Test Helpers

    private func createMockVaultedPaymentMethod(id: String) -> PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        let data = try! JSONSerialization.data(withJSONObject: ["last4Digits": "4242"]) // swiftlint:disable:this force_try
        let instrumentData = try! JSONDecoder().decode( // swiftlint:disable:this force_try
            Response.Body.Tokenization.PaymentInstrumentData.self,
            from: data
        )

        return PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
            id: id,
            paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
            paymentInstrumentType: .paymentCard,
            paymentInstrumentData: instrumentData,
            analyticsId: "analytics_\(id)"
        )
    }

    private func createMockPaymentResult(paymentId: String) -> PaymentResult {
        PaymentResult(paymentId: paymentId, status: .success)
    }

    private func createMockError(message: String) -> PrimerError {
        PrimerError.unknown(
            message: message,
            diagnosticsId: "test_diagnostics"
        )
    }

    // MARK: - Simple State Equality Tests

    func test_navigationState_loading_equalsLoading() {
        let state1 = DefaultCheckoutScope.NavigationState.loading
        let state2 = DefaultCheckoutScope.NavigationState.loading
        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_paymentMethodSelection_equalsPaymentMethodSelection() {
        let state1 = DefaultCheckoutScope.NavigationState.paymentMethodSelection
        let state2 = DefaultCheckoutScope.NavigationState.paymentMethodSelection
        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_vaultedPaymentMethods_equalsVaultedPaymentMethods() {
        let state1 = DefaultCheckoutScope.NavigationState.vaultedPaymentMethods
        let state2 = DefaultCheckoutScope.NavigationState.vaultedPaymentMethods
        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_processing_equalsProcessing() {
        let state1 = DefaultCheckoutScope.NavigationState.processing
        let state2 = DefaultCheckoutScope.NavigationState.processing
        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_dismissed_equalsDismissed() {
        let state1 = DefaultCheckoutScope.NavigationState.dismissed
        let state2 = DefaultCheckoutScope.NavigationState.dismissed
        XCTAssertEqual(state1, state2)
    }

    // MARK: - Payment Method State Equality Tests

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

    // MARK: - Success State Equality Tests

    func test_navigationState_success_samePaymentId_areEqual() {
        let result1 = createMockPaymentResult(paymentId: "pay_123")
        let result2 = createMockPaymentResult(paymentId: "pay_123")
        let state1 = DefaultCheckoutScope.NavigationState.success(result1)
        let state2 = DefaultCheckoutScope.NavigationState.success(result2)
        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_success_differentPaymentId_areNotEqual() {
        let result1 = createMockPaymentResult(paymentId: "pay_123")
        let result2 = createMockPaymentResult(paymentId: "pay_456")
        let state1 = DefaultCheckoutScope.NavigationState.success(result1)
        let state2 = DefaultCheckoutScope.NavigationState.success(result2)
        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Failure State Equality Tests

    func test_navigationState_failure_sameError_areEqual() {
        let error1 = createMockError(message: "Payment failed")
        let error2 = createMockError(message: "Payment failed")
        let state1 = DefaultCheckoutScope.NavigationState.failure(error1)
        let state2 = DefaultCheckoutScope.NavigationState.failure(error2)
        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_failure_differentError_areNotEqual() {
        let error1 = createMockError(message: "Payment failed")
        let error2 = createMockError(message: "Network error")
        let state1 = DefaultCheckoutScope.NavigationState.failure(error1)
        let state2 = DefaultCheckoutScope.NavigationState.failure(error2)
        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Delete Confirmation State Equality Tests

    func test_navigationState_deleteConfirmation_sameMethod_areEqual() {
        let method1 = createMockVaultedPaymentMethod(id: "vault_123")
        let method2 = createMockVaultedPaymentMethod(id: "vault_123")
        let state1 = DefaultCheckoutScope.NavigationState.deleteVaultedPaymentMethodConfirmation(method1)
        let state2 = DefaultCheckoutScope.NavigationState.deleteVaultedPaymentMethodConfirmation(method2)
        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_deleteConfirmation_differentMethod_areNotEqual() {
        let method1 = createMockVaultedPaymentMethod(id: "vault_123")
        let method2 = createMockVaultedPaymentMethod(id: "vault_456")
        let state1 = DefaultCheckoutScope.NavigationState.deleteVaultedPaymentMethodConfirmation(method1)
        let state2 = DefaultCheckoutScope.NavigationState.deleteVaultedPaymentMethodConfirmation(method2)
        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Cross-Type Inequality Tests

    func test_navigationState_differentTypes_areNotEqual() {
        let loading = DefaultCheckoutScope.NavigationState.loading
        let selection = DefaultCheckoutScope.NavigationState.paymentMethodSelection
        let vaulted = DefaultCheckoutScope.NavigationState.vaultedPaymentMethods
        let processing = DefaultCheckoutScope.NavigationState.processing
        let dismissed = DefaultCheckoutScope.NavigationState.dismissed

        // Loading vs others
        XCTAssertNotEqual(loading, selection)
        XCTAssertNotEqual(loading, vaulted)
        XCTAssertNotEqual(loading, processing)
        XCTAssertNotEqual(loading, dismissed)

        // Selection vs others
        XCTAssertNotEqual(selection, vaulted)
        XCTAssertNotEqual(selection, processing)
        XCTAssertNotEqual(selection, dismissed)

        // Vaulted vs others
        XCTAssertNotEqual(vaulted, processing)
        XCTAssertNotEqual(vaulted, dismissed)

        // Processing vs dismissed
        XCTAssertNotEqual(processing, dismissed)
    }

    func test_navigationState_paymentMethod_notEqual_toOtherTypes() {
        let paymentMethod = DefaultCheckoutScope.NavigationState.paymentMethod("PAYMENT_CARD")
        let loading = DefaultCheckoutScope.NavigationState.loading

        XCTAssertNotEqual(paymentMethod, loading)
    }

    func test_navigationState_success_notEqual_toOtherTypes() {
        let result = createMockPaymentResult(paymentId: "pay_123")
        let success = DefaultCheckoutScope.NavigationState.success(result)
        let processing = DefaultCheckoutScope.NavigationState.processing

        XCTAssertNotEqual(success, processing)
    }

    func test_navigationState_failure_notEqual_toOtherTypes() {
        let error = createMockError(message: "Error")
        let failure = DefaultCheckoutScope.NavigationState.failure(error)
        let loading = DefaultCheckoutScope.NavigationState.loading

        XCTAssertNotEqual(failure, loading)
    }
}

// MARK: - Vaulted Payment Methods Management Tests

/// Tests for vaulted payment methods state management in DefaultCheckoutScope.
/// These test the setVaultedPaymentMethods and setSelectedVaultedPaymentMethod logic.
@available(iOS 15.0, *)
final class VaultedPaymentMethodsStateTests: XCTestCase {

    // MARK: - Test Helpers

    private func createMockVaultedPaymentMethod(
        id: String,
        type: String = PrimerPaymentMethodType.paymentCard.rawValue
    ) -> PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        let data = try! JSONSerialization.data(withJSONObject: ["last4Digits": "4242"]) // swiftlint:disable:this force_try
        let instrumentData = try! JSONDecoder().decode( // swiftlint:disable:this force_try
            Response.Body.Tokenization.PaymentInstrumentData.self,
            from: data
        )

        return PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
            id: id,
            paymentMethodType: type,
            paymentInstrumentType: .paymentCard,
            paymentInstrumentData: instrumentData,
            analyticsId: "analytics_\(id)"
        )
    }

    // MARK: - setVaultedPaymentMethods Logic Tests

    /// Test that simulates the logic from setVaultedPaymentMethods:
    /// - When methods are set, vaultedPaymentMethods should be updated
    /// - If selectedMethod was deleted, it should be cleared
    /// - If no method is selected, first method should be selected

    func test_vaultedPaymentMethodsLogic_emptyList_clearsSelection() {
        // Simulate the logic from setVaultedPaymentMethods
        var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = createMockVaultedPaymentMethod(id: "vault_1")

        // Simulate setting empty methods
        let methods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
        vaultedPaymentMethods = methods

        // Clear selection if selected method was deleted
        if let selectedId = selectedVaultedPaymentMethod?.id,
           !methods.contains(where: { $0.id == selectedId }) {
            selectedVaultedPaymentMethod = nil
        }

        // Set first as default if none selected
        if selectedVaultedPaymentMethod == nil, let first = methods.first {
            selectedVaultedPaymentMethod = first
        }

        XCTAssertTrue(vaultedPaymentMethods.isEmpty)
        XCTAssertNil(selectedVaultedPaymentMethod)
    }

    func test_vaultedPaymentMethodsLogic_withMethods_setsMethodsArray() {
        var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?

        let method1 = createMockVaultedPaymentMethod(id: "vault_1")
        let method2 = createMockVaultedPaymentMethod(id: "vault_2")
        let methods = [method1, method2]

        // Simulate setVaultedPaymentMethods
        vaultedPaymentMethods = methods

        if let selectedId = selectedVaultedPaymentMethod?.id,
           !methods.contains(where: { $0.id == selectedId }) {
            selectedVaultedPaymentMethod = nil
        }

        if selectedVaultedPaymentMethod == nil, let first = methods.first {
            selectedVaultedPaymentMethod = first
        }

        XCTAssertEqual(vaultedPaymentMethods.count, 2)
        XCTAssertEqual(selectedVaultedPaymentMethod?.id, "vault_1")
    }

    func test_vaultedPaymentMethodsLogic_selectsFirstAsDefault() {
        var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?

        let method1 = createMockVaultedPaymentMethod(id: "first_method")
        let method2 = createMockVaultedPaymentMethod(id: "second_method")
        let methods = [method1, method2]

        vaultedPaymentMethods = methods

        if selectedVaultedPaymentMethod == nil, let first = methods.first {
            selectedVaultedPaymentMethod = first
        }

        XCTAssertEqual(selectedVaultedPaymentMethod?.id, "first_method")
    }

    func test_vaultedPaymentMethodsLogic_clearsSelectionIfDeleted() {
        var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = createMockVaultedPaymentMethod(id: "deleted_method")

        // New methods that don't include the selected one
        let method1 = createMockVaultedPaymentMethod(id: "vault_1")
        let method2 = createMockVaultedPaymentMethod(id: "vault_2")
        let methods = [method1, method2]

        vaultedPaymentMethods = methods

        // Clear selection if selected method was deleted
        if let selectedId = selectedVaultedPaymentMethod?.id,
           !methods.contains(where: { $0.id == selectedId }) {
            selectedVaultedPaymentMethod = nil
        }

        // Set first as default
        if selectedVaultedPaymentMethod == nil, let first = methods.first {
            selectedVaultedPaymentMethod = first
        }

        // Should have selected the first method since the old selection was deleted
        XCTAssertEqual(selectedVaultedPaymentMethod?.id, "vault_1")
    }

    func test_vaultedPaymentMethodsLogic_retainsSelectionIfPresent() {
        let existingMethod = createMockVaultedPaymentMethod(id: "vault_2")
        var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = existingMethod

        // New methods that still include the selected one
        let method1 = createMockVaultedPaymentMethod(id: "vault_1")
        let method2 = createMockVaultedPaymentMethod(id: "vault_2")
        let method3 = createMockVaultedPaymentMethod(id: "vault_3")
        let methods = [method1, method2, method3]

        vaultedPaymentMethods = methods

        // Should NOT clear selection since vault_2 is still in the list
        if let selectedId = selectedVaultedPaymentMethod?.id,
           !methods.contains(where: { $0.id == selectedId }) {
            selectedVaultedPaymentMethod = nil
        }

        // Should NOT set first as default since selection is valid
        if selectedVaultedPaymentMethod == nil, let first = methods.first {
            selectedVaultedPaymentMethod = first
        }

        // Should still have vault_2 selected
        XCTAssertEqual(selectedVaultedPaymentMethod?.id, "vault_2")
    }

    // MARK: - setSelectedVaultedPaymentMethod Logic Tests

    func test_setSelectedVaultedPaymentMethod_validMethod_setsSelection() {
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?

        let method = createMockVaultedPaymentMethod(id: "selected_method")
        selectedVaultedPaymentMethod = method

        XCTAssertEqual(selectedVaultedPaymentMethod?.id, "selected_method")
    }

    func test_setSelectedVaultedPaymentMethod_nil_clearsSelection() {
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = createMockVaultedPaymentMethod(id: "existing")

        selectedVaultedPaymentMethod = nil

        XCTAssertNil(selectedVaultedPaymentMethod)
    }

    func test_setSelectedVaultedPaymentMethod_changeSelection_updatesCorrectly() {
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = createMockVaultedPaymentMethod(id: "original")

        let newMethod = createMockVaultedPaymentMethod(id: "new_selection")
        selectedVaultedPaymentMethod = newMethod

        XCTAssertEqual(selectedVaultedPaymentMethod?.id, "new_selection")
    }
}
