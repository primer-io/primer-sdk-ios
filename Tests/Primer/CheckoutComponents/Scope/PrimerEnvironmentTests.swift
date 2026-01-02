//
//  PrimerEnvironmentTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

/// Tests for PrimerEnvironment keys and EnvironmentValues extensions.
@available(iOS 15.0, *)
final class PrimerEnvironmentTests: XCTestCase {

    // MARK: - primerCheckoutScope Tests

    func test_primerCheckoutScope_defaultValue_isNil() {
        // Given
        let environmentValues = EnvironmentValues()

        // Then
        XCTAssertNil(environmentValues.primerCheckoutScope)
    }

    func test_primerCheckoutScope_getterSetter_works() {
        // Given
        var environmentValues = EnvironmentValues()

        // When - verify getter works
        let initialValue = environmentValues.primerCheckoutScope

        // Then
        XCTAssertNil(initialValue)
    }

    // MARK: - primerCardFormScope Tests

    func test_primerCardFormScope_defaultValue_isNil() {
        // Given
        let environmentValues = EnvironmentValues()

        // Then
        XCTAssertNil(environmentValues.primerCardFormScope)
    }

    func test_primerCardFormScope_getterSetter_works() {
        // Given
        var environmentValues = EnvironmentValues()

        // When - verify getter works
        let initialValue = environmentValues.primerCardFormScope

        // Then
        XCTAssertNil(initialValue)
    }

    // MARK: - primerPaymentMethodSelectionScope Tests

    func test_primerPaymentMethodSelectionScope_defaultValue_isNil() {
        // Given
        let environmentValues = EnvironmentValues()

        // Then
        XCTAssertNil(environmentValues.primerPaymentMethodSelectionScope)
    }

    func test_primerPaymentMethodSelectionScope_getterSetter_works() {
        // Given
        var environmentValues = EnvironmentValues()

        // When - verify getter works
        let initialValue = environmentValues.primerPaymentMethodSelectionScope

        // Then
        XCTAssertNil(initialValue)
    }

    // MARK: - primerSelectCountryScope Tests

    func test_primerSelectCountryScope_defaultValue_isNil() {
        // Given
        let environmentValues = EnvironmentValues()

        // Then
        XCTAssertNil(environmentValues.primerSelectCountryScope)
    }

    func test_primerSelectCountryScope_getterSetter_works() {
        // Given
        var environmentValues = EnvironmentValues()

        // When - verify getter works
        let initialValue = environmentValues.primerSelectCountryScope

        // Then
        XCTAssertNil(initialValue)
    }

    // MARK: - Scope Value Setting and Retrieval Tests

    @MainActor
    func test_primerCheckoutScope_setAndRetrieve_returnsSameScope() async {
        // Given
        var environmentValues = EnvironmentValues()
        let mockScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        environmentValues.primerCheckoutScope = mockScope
        let retrievedScope = environmentValues.primerCheckoutScope

        // Then
        XCTAssertNotNil(retrievedScope)
        XCTAssertTrue(retrievedScope === mockScope)
    }

    @MainActor
    func test_primerCardFormScope_setAndRetrieve_returnsSameScope() {
        // Given
        var environmentValues = EnvironmentValues()
        let mockScope = MockCardFormScopeForEnvironmentTests()

        // When
        environmentValues.primerCardFormScope = mockScope
        let retrievedScope = environmentValues.primerCardFormScope

        // Then
        XCTAssertNotNil(retrievedScope)
    }

    @MainActor
    func test_primerPaymentMethodSelectionScope_setAndRetrieve_returnsSameScope() {
        // Given
        var environmentValues = EnvironmentValues()
        let mockScope = MockPaymentMethodSelectionScopeForEnvironmentTests()

        // When
        environmentValues.primerPaymentMethodSelectionScope = mockScope
        let retrievedScope = environmentValues.primerPaymentMethodSelectionScope

        // Then
        XCTAssertNotNil(retrievedScope)
        XCTAssertTrue(retrievedScope === mockScope)
    }

    @MainActor
    func test_primerSelectCountryScope_setAndRetrieve_returnsSameScope() {
        // Given
        var environmentValues = EnvironmentValues()
        let mockScope = MockSelectCountryScopeForEnvironmentTests()

        // When
        environmentValues.primerSelectCountryScope = mockScope
        let retrievedScope = environmentValues.primerSelectCountryScope

        // Then
        XCTAssertNotNil(retrievedScope)
        XCTAssertTrue(retrievedScope === mockScope)
    }

    // MARK: - Scope Independence Tests

    @MainActor
    func test_settingOneScope_doesNotAffectOthers() async {
        // Given
        var environmentValues = EnvironmentValues()
        let mockCheckoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // Verify all start as nil
        XCTAssertNil(environmentValues.primerCheckoutScope)
        XCTAssertNil(environmentValues.primerCardFormScope)
        XCTAssertNil(environmentValues.primerPaymentMethodSelectionScope)
        XCTAssertNil(environmentValues.primerSelectCountryScope)

        // When - set only checkout scope
        environmentValues.primerCheckoutScope = mockCheckoutScope

        // Then - only checkout scope should be set
        XCTAssertNotNil(environmentValues.primerCheckoutScope)
        XCTAssertNil(environmentValues.primerCardFormScope)
        XCTAssertNil(environmentValues.primerPaymentMethodSelectionScope)
        XCTAssertNil(environmentValues.primerSelectCountryScope)
    }

    @MainActor
    func test_allScopes_canBeSetIndependently() {
        // Given
        var environmentValues = EnvironmentValues()
        let mockCardFormScope = MockCardFormScopeForEnvironmentTests()
        let mockSelectionScope = MockPaymentMethodSelectionScopeForEnvironmentTests()
        let mockCountryScope = MockSelectCountryScopeForEnvironmentTests()

        // When - set multiple scopes
        environmentValues.primerCardFormScope = mockCardFormScope
        environmentValues.primerPaymentMethodSelectionScope = mockSelectionScope
        environmentValues.primerSelectCountryScope = mockCountryScope

        // Then - all scopes should be retrievable
        XCTAssertNotNil(environmentValues.primerCardFormScope)
        XCTAssertNotNil(environmentValues.primerPaymentMethodSelectionScope)
        XCTAssertNotNil(environmentValues.primerSelectCountryScope)
    }

    // MARK: - Nil Handling Tests

    @MainActor
    func test_primerCheckoutScope_setToNil_becomesNil() async {
        // Given
        var environmentValues = EnvironmentValues()
        let mockScope = await ContainerTestHelpers.createMockCheckoutScope()
        environmentValues.primerCheckoutScope = mockScope
        XCTAssertNotNil(environmentValues.primerCheckoutScope)

        // When
        environmentValues.primerCheckoutScope = nil

        // Then
        XCTAssertNil(environmentValues.primerCheckoutScope)
    }

    @MainActor
    func test_primerCardFormScope_setToNil_becomesNil() {
        // Given
        var environmentValues = EnvironmentValues()
        let mockScope = MockCardFormScopeForEnvironmentTests()
        environmentValues.primerCardFormScope = mockScope
        XCTAssertNotNil(environmentValues.primerCardFormScope)

        // When
        environmentValues.primerCardFormScope = nil

        // Then
        XCTAssertNil(environmentValues.primerCardFormScope)
    }

    @MainActor
    func test_primerPaymentMethodSelectionScope_setToNil_becomesNil() {
        // Given
        var environmentValues = EnvironmentValues()
        let mockScope = MockPaymentMethodSelectionScopeForEnvironmentTests()
        environmentValues.primerPaymentMethodSelectionScope = mockScope
        XCTAssertNotNil(environmentValues.primerPaymentMethodSelectionScope)

        // When
        environmentValues.primerPaymentMethodSelectionScope = nil

        // Then
        XCTAssertNil(environmentValues.primerPaymentMethodSelectionScope)
    }

    @MainActor
    func test_primerSelectCountryScope_setToNil_becomesNil() {
        // Given
        var environmentValues = EnvironmentValues()
        let mockScope = MockSelectCountryScopeForEnvironmentTests()
        environmentValues.primerSelectCountryScope = mockScope
        XCTAssertNotNil(environmentValues.primerSelectCountryScope)

        // When
        environmentValues.primerSelectCountryScope = nil

        // Then
        XCTAssertNil(environmentValues.primerSelectCountryScope)
    }

    // MARK: - Scope Replacement Tests

    @MainActor
    func test_primerCardFormScope_canBeReplaced() {
        // Given
        var environmentValues = EnvironmentValues()
        let firstScope = MockCardFormScopeForEnvironmentTests()
        let secondScope = MockCardFormScopeForEnvironmentTests()
        environmentValues.primerCardFormScope = firstScope

        // When
        environmentValues.primerCardFormScope = secondScope

        // Then - should have the second scope
        XCTAssertNotNil(environmentValues.primerCardFormScope)
    }

    @MainActor
    func test_primerPaymentMethodSelectionScope_canBeReplaced() {
        // Given
        var environmentValues = EnvironmentValues()
        let firstScope = MockPaymentMethodSelectionScopeForEnvironmentTests()
        let secondScope = MockPaymentMethodSelectionScopeForEnvironmentTests()
        environmentValues.primerPaymentMethodSelectionScope = firstScope

        // When
        environmentValues.primerPaymentMethodSelectionScope = secondScope

        // Then
        XCTAssertNotNil(environmentValues.primerPaymentMethodSelectionScope)
        XCTAssertTrue(environmentValues.primerPaymentMethodSelectionScope === secondScope)
    }
}

// MARK: - Mock Scopes for Environment Tests

@available(iOS 15.0, *)
private final class MockCardFormScopeForEnvironmentTests: PrimerCardFormScope {
    typealias State = StructuredCardFormState

    var state: AsyncStream<StructuredCardFormState> {
        AsyncStream { continuation in
            continuation.yield(StructuredCardFormState())
            continuation.finish()
        }
    }

    var presentationContext: PresentationContext = .direct
    var cardFormUIOptions: PrimerCardFormUIOptions?
    var dismissalMechanism: [DismissalMechanism] = []
    var selectCountry: PrimerSelectCountryScope { fatalError("Not implemented") }

    var title: String?
    var screen: CardFormScreenComponent?
    var cobadgedCardsView: (([String], @escaping (String) -> Void) -> any View)?
    var errorView: ErrorComponent?
    var submitButtonText: String?
    var showSubmitLoadingIndicator: Bool = false

    var cardNumberConfig: InputFieldConfig?
    var expiryDateConfig: InputFieldConfig?
    var cvvConfig: InputFieldConfig?
    var cardholderNameConfig: InputFieldConfig?
    var postalCodeConfig: InputFieldConfig?
    var countryConfig: InputFieldConfig?
    var cityConfig: InputFieldConfig?
    var stateConfig: InputFieldConfig?
    var addressLine1Config: InputFieldConfig?
    var addressLine2Config: InputFieldConfig?
    var phoneNumberConfig: InputFieldConfig?
    var firstNameConfig: InputFieldConfig?
    var lastNameConfig: InputFieldConfig?
    var emailConfig: InputFieldConfig?
    var retailOutletConfig: InputFieldConfig?
    var otpCodeConfig: InputFieldConfig?

    var cardInputSection: Component?
    var billingAddressSection: Component?
    var submitButtonSection: Component?

    func start() {}
    func submit() {}
    func cancel() {}
    func onSubmit() {}
    func onBack() {}
    func onCancel() {}

    func updateField(_ fieldType: PrimerInputElementType, value: String) {}
    func getFieldValue(_ fieldType: PrimerInputElementType) -> String { "" }
    func setFieldError(_ fieldType: PrimerInputElementType, message: String, errorCode: String?) {}
    func clearFieldError(_ fieldType: PrimerInputElementType) {}
    func getFieldError(_ fieldType: PrimerInputElementType) -> String? { nil }
    func getFormConfiguration() -> CardFormConfiguration { .default }

    func updateCardNumber(_ cardNumber: String) {}
    func updateCvv(_ cvv: String) {}
    func updateExpiryDate(_ expiryDate: String) {}
    func updateCardholderName(_ cardholderName: String) {}
    func updatePostalCode(_ postalCode: String) {}
    func updateCity(_ city: String) {}
    func updateState(_ state: String) {}
    func updateAddressLine1(_ addressLine1: String) {}
    func updateAddressLine2(_ addressLine2: String) {}
    func updatePhoneNumber(_ phoneNumber: String) {}
    func updateFirstName(_ firstName: String) {}
    func updateLastName(_ lastName: String) {}
    func updateRetailOutlet(_ retailOutlet: String) {}
    func updateOtpCode(_ otpCode: String) {}
    func updateEmail(_ email: String) {}
    func updateExpiryMonth(_ month: String) {}
    func updateExpiryYear(_ year: String) {}
    func updateSelectedCardNetwork(_ network: String) {}
    func updateCountryCode(_ countryCode: String) {}

    func PrimerCardNumberField(label: String?, styling: PrimerFieldStyling?) -> AnyView { AnyView(EmptyView()) }
    func PrimerExpiryDateField(label: String?, styling: PrimerFieldStyling?) -> AnyView { AnyView(EmptyView()) }
    func PrimerCvvField(label: String?, styling: PrimerFieldStyling?) -> AnyView { AnyView(EmptyView()) }
    func PrimerCardholderNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView { AnyView(EmptyView()) }
    func PrimerCountryField(label: String?, styling: PrimerFieldStyling?) -> AnyView { AnyView(EmptyView()) }
    func PrimerPostalCodeField(label: String?, styling: PrimerFieldStyling?) -> AnyView { AnyView(EmptyView()) }
    func PrimerCityField(label: String?, styling: PrimerFieldStyling?) -> AnyView { AnyView(EmptyView()) }
    func PrimerStateField(label: String?, styling: PrimerFieldStyling?) -> AnyView { AnyView(EmptyView()) }
    func PrimerAddressLine1Field(label: String?, styling: PrimerFieldStyling?) -> AnyView { AnyView(EmptyView()) }
    func PrimerAddressLine2Field(label: String?, styling: PrimerFieldStyling?) -> AnyView { AnyView(EmptyView()) }
    func PrimerFirstNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView { AnyView(EmptyView()) }
    func PrimerLastNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView { AnyView(EmptyView()) }
    func PrimerEmailField(label: String?, styling: PrimerFieldStyling?) -> AnyView { AnyView(EmptyView()) }
    func PrimerPhoneNumberField(label: String?, styling: PrimerFieldStyling?) -> AnyView { AnyView(EmptyView()) }
    func PrimerRetailOutletField(label: String?, styling: PrimerFieldStyling?) -> AnyView { AnyView(EmptyView()) }
    func PrimerOtpCodeField(label: String?, styling: PrimerFieldStyling?) -> AnyView { AnyView(EmptyView()) }

    func updateValidationState(cardNumber: Bool, cvv: Bool, expiry: Bool, cardholderName: Bool) {}
    func DefaultCardFormView(styling: PrimerFieldStyling?) -> AnyView { AnyView(EmptyView()) }
}

@available(iOS 15.0, *)
private final class MockPaymentMethodSelectionScopeForEnvironmentTests: PrimerPaymentMethodSelectionScope {
    var state: AsyncStream<PrimerPaymentMethodSelectionState> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    var dismissalMechanism: [DismissalMechanism] = []
    var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?
    var screen: PaymentMethodSelectionScreenComponent?
    var paymentMethodItem: PaymentMethodItemComponent?
    var categoryHeader: CategoryHeaderComponent?
    var emptyStateView: Component?

    func onPaymentMethodSelected(paymentMethod: CheckoutPaymentMethod) {}
    func onCancel() {}
    func payWithVaultedPaymentMethod() async {}
    func payWithVaultedPaymentMethodAndCvv(_ cvv: String) async {}
    func updateCvvInput(_ cvv: String) {}
    func showAllVaultedPaymentMethods() {}
    func showOtherWaysToPay() {}
}

@available(iOS 15.0, *)
private final class MockSelectCountryScopeForEnvironmentTests: PrimerSelectCountryScope {
    var state: AsyncStream<PrimerSelectCountryState> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    var screen: ((_ scope: PrimerSelectCountryScope) -> AnyView)?
    var searchBar: ((_ query: String, _ onQueryChange: @escaping (String) -> Void, _ placeholder: String) -> AnyView)?
    var countryItem: CountryItemComponent?

    func onCountrySelected(countryCode: String, countryName: String) {}
    func onCancel() {}
    func onSearch(query: String) {}
}
