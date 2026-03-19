//
//  DefaultCheckoutScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class NavigationStateEqualityTests: XCTestCase {

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

    // MARK: - Simple State Equality

    func test_navigationState_loading_equalsLoading() {
        XCTAssertEqual(
            DefaultCheckoutScope.NavigationState.loading,
            DefaultCheckoutScope.NavigationState.loading
        )
    }

    func test_navigationState_paymentMethodSelection_equalsPaymentMethodSelection() {
        XCTAssertEqual(
            DefaultCheckoutScope.NavigationState.paymentMethodSelection,
            DefaultCheckoutScope.NavigationState.paymentMethodSelection
        )
    }

    func test_navigationState_vaultedPaymentMethods_equalsVaultedPaymentMethods() {
        XCTAssertEqual(
            DefaultCheckoutScope.NavigationState.vaultedPaymentMethods,
            DefaultCheckoutScope.NavigationState.vaultedPaymentMethods
        )
    }

    func test_navigationState_processing_equalsProcessing() {
        XCTAssertEqual(
            DefaultCheckoutScope.NavigationState.processing,
            DefaultCheckoutScope.NavigationState.processing
        )
    }

    func test_navigationState_dismissed_equalsDismissed() {
        XCTAssertEqual(
            DefaultCheckoutScope.NavigationState.dismissed,
            DefaultCheckoutScope.NavigationState.dismissed
        )
    }

    // MARK: - Payment Method State Equality

    func test_navigationState_paymentMethod_sameType_areEqual() {
        XCTAssertEqual(
            DefaultCheckoutScope.NavigationState.paymentMethod("PAYMENT_CARD"),
            DefaultCheckoutScope.NavigationState.paymentMethod("PAYMENT_CARD")
        )
    }

    func test_navigationState_paymentMethod_differentType_areNotEqual() {
        XCTAssertNotEqual(
            DefaultCheckoutScope.NavigationState.paymentMethod("PAYMENT_CARD"),
            DefaultCheckoutScope.NavigationState.paymentMethod("PAYPAL")
        )
    }

    // MARK: - Success State Equality

    func test_navigationState_success_samePaymentId_areEqual() {
        let state1 = DefaultCheckoutScope.NavigationState.success(createMockPaymentResult(paymentId: "pay_123"))
        let state2 = DefaultCheckoutScope.NavigationState.success(createMockPaymentResult(paymentId: "pay_123"))
        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_success_differentPaymentId_areNotEqual() {
        let state1 = DefaultCheckoutScope.NavigationState.success(createMockPaymentResult(paymentId: "pay_123"))
        let state2 = DefaultCheckoutScope.NavigationState.success(createMockPaymentResult(paymentId: "pay_456"))
        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Failure State Equality

    func test_navigationState_failure_sameError_areEqual() {
        let state1 = DefaultCheckoutScope.NavigationState.failure(createMockError(message: "Payment failed"))
        let state2 = DefaultCheckoutScope.NavigationState.failure(createMockError(message: "Payment failed"))
        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_failure_differentError_areNotEqual() {
        let state1 = DefaultCheckoutScope.NavigationState.failure(createMockError(message: "Payment failed"))
        let state2 = DefaultCheckoutScope.NavigationState.failure(createMockError(message: "Network error"))
        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Delete Confirmation State Equality

    func test_navigationState_deleteConfirmation_sameMethod_areEqual() {
        let state1 = DefaultCheckoutScope.NavigationState.deleteVaultedPaymentMethodConfirmation(createMockVaultedPaymentMethod(id: "vault_123"))
        let state2 = DefaultCheckoutScope.NavigationState.deleteVaultedPaymentMethodConfirmation(createMockVaultedPaymentMethod(id: "vault_123"))
        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_deleteConfirmation_differentMethod_areNotEqual() {
        let state1 = DefaultCheckoutScope.NavigationState.deleteVaultedPaymentMethodConfirmation(createMockVaultedPaymentMethod(id: "vault_123"))
        let state2 = DefaultCheckoutScope.NavigationState.deleteVaultedPaymentMethodConfirmation(createMockVaultedPaymentMethod(id: "vault_456"))
        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Cross-Type Inequality

    func test_navigationState_differentTypes_areNotEqual() {
        let loading = DefaultCheckoutScope.NavigationState.loading
        let selection = DefaultCheckoutScope.NavigationState.paymentMethodSelection
        let vaulted = DefaultCheckoutScope.NavigationState.vaultedPaymentMethods
        let processing = DefaultCheckoutScope.NavigationState.processing
        let dismissed = DefaultCheckoutScope.NavigationState.dismissed

        XCTAssertNotEqual(loading, selection)
        XCTAssertNotEqual(loading, vaulted)
        XCTAssertNotEqual(loading, processing)
        XCTAssertNotEqual(loading, dismissed)
        XCTAssertNotEqual(selection, vaulted)
        XCTAssertNotEqual(selection, processing)
        XCTAssertNotEqual(selection, dismissed)
        XCTAssertNotEqual(vaulted, processing)
        XCTAssertNotEqual(vaulted, dismissed)
        XCTAssertNotEqual(processing, dismissed)
    }

    func test_navigationState_paymentMethod_notEqual_toOtherTypes() {
        XCTAssertNotEqual(
            DefaultCheckoutScope.NavigationState.paymentMethod("PAYMENT_CARD"),
            DefaultCheckoutScope.NavigationState.loading
        )
    }

    func test_navigationState_success_notEqual_toOtherTypes() {
        XCTAssertNotEqual(
            DefaultCheckoutScope.NavigationState.success(createMockPaymentResult(paymentId: "pay_123")),
            DefaultCheckoutScope.NavigationState.processing
        )
    }

    func test_navigationState_failure_notEqual_toOtherTypes() {
        XCTAssertNotEqual(
            DefaultCheckoutScope.NavigationState.failure(createMockError(message: "Error")),
            DefaultCheckoutScope.NavigationState.loading
        )
    }
}

// MARK: - Vaulted Payment Methods Management Tests

@available(iOS 15.0, *)
final class VaultedPaymentMethodsStateTests: XCTestCase {

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

    func test_vaultedPaymentMethods_emptyList_clearsSelection() {
        // Given
        var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = createMockVaultedPaymentMethod(id: "vault_1")
        let methods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []

        // When
        vaultedPaymentMethods = methods

        if let selectedId = selectedVaultedPaymentMethod?.id,
           !methods.contains(where: { $0.id == selectedId }) {
            selectedVaultedPaymentMethod = nil
        }

        if selectedVaultedPaymentMethod == nil, let first = methods.first {
            selectedVaultedPaymentMethod = first
        }

        // Then
        XCTAssertTrue(vaultedPaymentMethods.isEmpty)
        XCTAssertNil(selectedVaultedPaymentMethod)
    }

    func test_vaultedPaymentMethods_withMethods_setsMethodsArray() {
        // Given
        var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?
        let methods = [createMockVaultedPaymentMethod(id: "vault_1"), createMockVaultedPaymentMethod(id: "vault_2")]

        // When
        vaultedPaymentMethods = methods

        if let selectedId = selectedVaultedPaymentMethod?.id,
           !methods.contains(where: { $0.id == selectedId }) {
            selectedVaultedPaymentMethod = nil
        }

        if selectedVaultedPaymentMethod == nil, let first = methods.first {
            selectedVaultedPaymentMethod = first
        }

        // Then
        XCTAssertEqual(vaultedPaymentMethods.count, 2)
        XCTAssertEqual(selectedVaultedPaymentMethod?.id, "vault_1")
    }

    func test_vaultedPaymentMethods_selectsFirstAsDefault() {
        // Given
        var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?
        let methods = [createMockVaultedPaymentMethod(id: "first_method"), createMockVaultedPaymentMethod(id: "second_method")]

        // When
        vaultedPaymentMethods = methods

        if selectedVaultedPaymentMethod == nil, let first = methods.first {
            selectedVaultedPaymentMethod = first
        }

        // Then
        XCTAssertEqual(vaultedPaymentMethods.count, 2)
        XCTAssertEqual(selectedVaultedPaymentMethod?.id, "first_method")
    }

    func test_vaultedPaymentMethods_clearsSelectionIfDeleted() {
        // Given
        var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = createMockVaultedPaymentMethod(id: "deleted_method")
        let methods = [createMockVaultedPaymentMethod(id: "vault_1"), createMockVaultedPaymentMethod(id: "vault_2")]

        // When
        vaultedPaymentMethods = methods

        if let selectedId = selectedVaultedPaymentMethod?.id,
           !methods.contains(where: { $0.id == selectedId }) {
            selectedVaultedPaymentMethod = nil
        }

        if selectedVaultedPaymentMethod == nil, let first = methods.first {
            selectedVaultedPaymentMethod = first
        }

        // Then
        XCTAssertEqual(vaultedPaymentMethods.count, 2)
        XCTAssertEqual(selectedVaultedPaymentMethod?.id, "vault_1")
    }

    func test_vaultedPaymentMethods_retainsSelectionIfPresent() {
        // Given
        var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = createMockVaultedPaymentMethod(id: "vault_2")
        let methods = [
            createMockVaultedPaymentMethod(id: "vault_1"),
            createMockVaultedPaymentMethod(id: "vault_2"),
            createMockVaultedPaymentMethod(id: "vault_3")
        ]

        // When
        vaultedPaymentMethods = methods

        if let selectedId = selectedVaultedPaymentMethod?.id,
           !methods.contains(where: { $0.id == selectedId }) {
            selectedVaultedPaymentMethod = nil
        }

        if selectedVaultedPaymentMethod == nil, let first = methods.first {
            selectedVaultedPaymentMethod = first
        }

        // Then
        XCTAssertEqual(vaultedPaymentMethods.count, 3)
        XCTAssertEqual(selectedVaultedPaymentMethod?.id, "vault_2")
    }

    func test_setSelectedVaultedPaymentMethod_validMethod_setsSelection() {
        // Given / When
        let selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = createMockVaultedPaymentMethod(id: "selected_method")

        // Then
        XCTAssertEqual(selectedVaultedPaymentMethod?.id, "selected_method")
    }

    func test_setSelectedVaultedPaymentMethod_nil_clearsSelection() {
        // Given
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = createMockVaultedPaymentMethod(id: "existing")

        // When
        selectedVaultedPaymentMethod = nil

        // Then
        XCTAssertNil(selectedVaultedPaymentMethod)
    }

    func test_setSelectedVaultedPaymentMethod_changeSelection_updatesCorrectly() {
        // Given
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = createMockVaultedPaymentMethod(id: "original")

        // When
        selectedVaultedPaymentMethod = createMockVaultedPaymentMethod(id: "new_selection")

        // Then
        XCTAssertEqual(selectedVaultedPaymentMethod?.id, "new_selection")
    }
}
