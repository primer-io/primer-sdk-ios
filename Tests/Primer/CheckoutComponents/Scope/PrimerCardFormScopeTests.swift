//
//  PrimerCardFormScopeTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

// MARK: - PrimerCardFormScope Protocol Extension Tests

/// Tests for the default implementations provided in PrimerCardFormScope protocol extensions.
/// These tests verify the updateField dispatch logic and default return values.
@available(iOS 15.0, *)
@MainActor
final class PrimerCardFormScopeTests: XCTestCase {

    // MARK: - Test Doubles

    /// Mock implementation of PrimerCardFormScope for testing protocol extension defaults
    private class MockCardFormScopeImpl: PrimerCardFormScope {
        typealias State = StructuredCardFormState

        // Track which update methods were called
        var updatedFields: [PrimerInputElementType: String] = [:]

        // Protocol requirements
        var state: AsyncStream<StructuredCardFormState> {
            AsyncStream { continuation in
                continuation.yield(StructuredCardFormState())
                continuation.finish()
            }
        }

        var presentationContext: PresentationContext = .direct
        var cardFormUIOptions: PrimerCardFormUIOptions?
        var dismissalMechanism: [DismissalMechanism] = []
        var selectCountry: PrimerSelectCountryScope { fatalError("Not implemented for test") }

        // Customization properties
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

        // Navigation methods
        func onSubmit() {}
        func onBack() {}
        func onCancel() {}

        // Update methods - track calls
        func updateCardNumber(_ cardNumber: String) {
            updatedFields[.cardNumber] = cardNumber
        }

        func updateCvv(_ cvv: String) {
            updatedFields[.cvv] = cvv
        }

        func updateExpiryDate(_ expiryDate: String) {
            updatedFields[.expiryDate] = expiryDate
        }

        func updateCardholderName(_ cardholderName: String) {
            updatedFields[.cardholderName] = cardholderName
        }

        func updatePostalCode(_ postalCode: String) {
            updatedFields[.postalCode] = postalCode
        }

        func updateCity(_ city: String) {
            updatedFields[.city] = city
        }

        func updateState(_ state: String) {
            updatedFields[.state] = state
        }

        func updateAddressLine1(_ addressLine1: String) {
            updatedFields[.addressLine1] = addressLine1
        }

        func updateAddressLine2(_ addressLine2: String) {
            updatedFields[.addressLine2] = addressLine2
        }

        func updatePhoneNumber(_ phoneNumber: String) {
            updatedFields[.phoneNumber] = phoneNumber
        }

        func updateFirstName(_ firstName: String) {
            updatedFields[.firstName] = firstName
        }

        func updateLastName(_ lastName: String) {
            updatedFields[.lastName] = lastName
        }

        func updateRetailOutlet(_ retailOutlet: String) {
            updatedFields[.retailer] = retailOutlet
        }

        func updateOtpCode(_ otpCode: String) {
            updatedFields[.otp] = otpCode
        }

        func updateEmail(_ email: String) {
            updatedFields[.email] = email
        }

        func updateExpiryMonth(_ month: String) {}
        func updateExpiryYear(_ year: String) {}
        func updateSelectedCardNetwork(_ network: String) {}
        func updateCountryCode(_ countryCode: String) {
            updatedFields[.countryCode] = countryCode
        }

        // ViewBuilder methods
        func PrimerCardNumberField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerExpiryDateField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerCvvField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerCardholderNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerCountryField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerPostalCodeField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerCityField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerStateField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerAddressLine1Field(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerAddressLine2Field(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerFirstNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerLastNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerEmailField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerPhoneNumberField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerRetailOutletField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerOtpCodeField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func updateValidationState(cardNumber: Bool, cvv: Bool, expiry: Bool, cardholderName: Bool) {}

        func DefaultCardFormView(styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }
    }

    // MARK: - updateField Dispatch Tests

    func test_updateField_cardNumber_dispatchesToUpdateCardNumber() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.cardNumber, value: "4111111111111111")

        XCTAssertEqual(scope.updatedFields[.cardNumber], "4111111111111111")
    }

    func test_updateField_cvv_dispatchesToUpdateCvv() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.cvv, value: "123")

        XCTAssertEqual(scope.updatedFields[.cvv], "123")
    }

    func test_updateField_expiryDate_dispatchesToUpdateExpiryDate() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.expiryDate, value: "12/25")

        XCTAssertEqual(scope.updatedFields[.expiryDate], "12/25")
    }

    func test_updateField_cardholderName_dispatchesToUpdateCardholderName() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.cardholderName, value: "John Doe")

        XCTAssertEqual(scope.updatedFields[.cardholderName], "John Doe")
    }

    func test_updateField_postalCode_dispatchesToUpdatePostalCode() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.postalCode, value: "12345")

        XCTAssertEqual(scope.updatedFields[.postalCode], "12345")
    }

    func test_updateField_countryCode_dispatchesToUpdateCountryCode() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.countryCode, value: "US")

        XCTAssertEqual(scope.updatedFields[.countryCode], "US")
    }

    func test_updateField_city_dispatchesToUpdateCity() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.city, value: "New York")

        XCTAssertEqual(scope.updatedFields[.city], "New York")
    }

    func test_updateField_state_dispatchesToUpdateState() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.state, value: "NY")

        XCTAssertEqual(scope.updatedFields[.state], "NY")
    }

    func test_updateField_addressLine1_dispatchesToUpdateAddressLine1() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.addressLine1, value: "123 Main St")

        XCTAssertEqual(scope.updatedFields[.addressLine1], "123 Main St")
    }

    func test_updateField_addressLine2_dispatchesToUpdateAddressLine2() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.addressLine2, value: "Apt 4B")

        XCTAssertEqual(scope.updatedFields[.addressLine2], "Apt 4B")
    }

    func test_updateField_phoneNumber_dispatchesToUpdatePhoneNumber() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.phoneNumber, value: "+1234567890")

        XCTAssertEqual(scope.updatedFields[.phoneNumber], "+1234567890")
    }

    func test_updateField_firstName_dispatchesToUpdateFirstName() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.firstName, value: "John")

        XCTAssertEqual(scope.updatedFields[.firstName], "John")
    }

    func test_updateField_lastName_dispatchesToUpdateLastName() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.lastName, value: "Doe")

        XCTAssertEqual(scope.updatedFields[.lastName], "Doe")
    }

    func test_updateField_email_dispatchesToUpdateEmail() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.email, value: "john@example.com")

        XCTAssertEqual(scope.updatedFields[.email], "john@example.com")
    }

    func test_updateField_retailer_dispatchesToUpdateRetailOutlet() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.retailer, value: "Store123")

        XCTAssertEqual(scope.updatedFields[.retailer], "Store123")
    }

    func test_updateField_otp_dispatchesToUpdateOtpCode() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.otp, value: "123456")

        XCTAssertEqual(scope.updatedFields[.otp], "123456")
    }

    func test_updateField_unknown_doesNotDispatch() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.unknown, value: "test")

        XCTAssertNil(scope.updatedFields[.unknown])
    }

    func test_updateField_all_doesNotDispatch() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.all, value: "test")

        XCTAssertNil(scope.updatedFields[.all])
    }

    // MARK: - Default Implementation Return Value Tests

    func test_getFieldValue_defaultImplementation_returnsEmptyString() {
        let scope = MockCardFormScopeImpl()

        let value = scope.getFieldValue(.cardNumber)

        XCTAssertEqual(value, "")
    }

    func test_getFieldError_defaultImplementation_returnsNil() {
        let scope = MockCardFormScopeImpl()

        let error = scope.getFieldError(.cardNumber)

        XCTAssertNil(error)
    }

    func test_getFormConfiguration_defaultImplementation_returnsDefault() {
        let scope = MockCardFormScopeImpl()

        let config = scope.getFormConfiguration()

        XCTAssertEqual(config, CardFormConfiguration.default)
    }

    // MARK: - Lifecycle Default Implementation Tests

    func test_start_defaultImplementation_doesNothing() {
        let scope = MockCardFormScopeImpl()

        // Should not throw or crash
        scope.start()

        XCTAssertTrue(true, "start() default implementation should complete without error")
    }

    func test_submit_callsOnSubmit() {
        var onSubmitCalled = false

        final class TrackingScope: MockCardFormScopeImpl {
            var onSubmitHandler: (() -> Void)?

            override func onSubmit() {
                onSubmitHandler?()
            }
        }

        let scope = TrackingScope()
        scope.onSubmitHandler = { onSubmitCalled = true }

        scope.submit()

        XCTAssertTrue(onSubmitCalled)
    }

    func test_cancel_callsOnCancel() {
        var onCancelCalled = false

        final class TrackingScope: MockCardFormScopeImpl {
            var onCancelHandler: (() -> Void)?

            override func onCancel() {
                onCancelHandler?()
            }
        }

        let scope = TrackingScope()
        scope.onCancelHandler = { onCancelCalled = true }

        scope.cancel()

        XCTAssertTrue(onCancelCalled)
    }

    // MARK: - All Field Types Dispatch Test

    func test_updateField_allCardFields_dispatchCorrectly() {
        let scope = MockCardFormScopeImpl()
        let testValue = "test_value"

        // Card fields
        let cardFields: [PrimerInputElementType] = [
            .cardNumber, .cvv, .expiryDate, .cardholderName
        ]

        for field in cardFields {
            scope.updateField(field, value: testValue)
            XCTAssertNotNil(scope.updatedFields[field], "Field \(field) should be updated")
        }
    }

    func test_updateField_allBillingFields_dispatchCorrectly() {
        let scope = MockCardFormScopeImpl()
        let testValue = "test_value"

        // Billing address fields
        let billingFields: [PrimerInputElementType] = [
            .postalCode, .countryCode, .city, .state,
            .addressLine1, .addressLine2, .phoneNumber,
            .firstName, .lastName, .email
        ]

        for field in billingFields {
            scope.updateField(field, value: testValue)
            XCTAssertNotNil(scope.updatedFields[field], "Field \(field) should be updated")
        }
    }

    func test_updateField_otherFields_dispatchCorrectly() {
        let scope = MockCardFormScopeImpl()
        let testValue = "test_value"

        // Other fields
        scope.updateField(.retailer, value: testValue)
        XCTAssertNotNil(scope.updatedFields[.retailer])

        scope.updateField(.otp, value: testValue)
        XCTAssertNotNil(scope.updatedFields[.otp])
    }
}
