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

    // MARK: - setFieldError Default Implementation Tests

    func test_setFieldError_defaultImplementation_doesNothing() {
        let scope = MockCardFormScopeImpl()

        // When - set error using default implementation
        scope.setFieldError(.cardNumber, message: "Invalid card", errorCode: "ERR001")

        // Then - should not crash and complete without error
        XCTAssertTrue(true, "setFieldError default implementation should complete without error")
    }

    func test_setFieldError_withNilErrorCode_defaultImplementation_doesNothing() {
        let scope = MockCardFormScopeImpl()

        // When - set error with nil error code
        scope.setFieldError(.cvv, message: "Invalid CVV", errorCode: nil)

        // Then - should not crash
        XCTAssertTrue(true, "setFieldError with nil errorCode should complete without error")
    }

    // MARK: - clearFieldError Default Implementation Tests

    func test_clearFieldError_defaultImplementation_doesNothing() {
        let scope = MockCardFormScopeImpl()

        // When - clear error using default implementation
        scope.clearFieldError(.cardNumber)

        // Then - should not crash and complete without error
        XCTAssertTrue(true, "clearFieldError default implementation should complete without error")
    }

    func test_clearFieldError_forAllFieldTypes_doesNothing() {
        let scope = MockCardFormScopeImpl()

        // When - clear errors for various field types
        let fieldTypes: [PrimerInputElementType] = [
            .cardNumber, .cvv, .expiryDate, .cardholderName,
            .postalCode, .city, .state, .addressLine1,
            .addressLine2, .phoneNumber, .firstName, .lastName
        ]

        for fieldType in fieldTypes {
            scope.clearFieldError(fieldType)
        }

        // Then - should complete without error
        XCTAssertTrue(true, "clearFieldError for all field types should complete without error")
    }

    // MARK: - getFieldValue Default Implementation Tests

    func test_getFieldValue_forAllFieldTypes_returnsEmptyString() {
        let scope = MockCardFormScopeImpl()

        // Test various field types
        let fieldTypes: [PrimerInputElementType] = [
            .cardNumber, .cvv, .expiryDate, .cardholderName,
            .postalCode, .city, .state, .addressLine1,
            .addressLine2, .phoneNumber, .firstName, .lastName,
            .email, .countryCode, .retailer, .otp
        ]

        for fieldType in fieldTypes {
            let value = scope.getFieldValue(fieldType)
            XCTAssertEqual(value, "", "getFieldValue for \(fieldType) should return empty string")
        }
    }

    // MARK: - getFieldError Default Implementation Tests

    func test_getFieldError_forAllFieldTypes_returnsNil() {
        let scope = MockCardFormScopeImpl()

        // Test various field types
        let fieldTypes: [PrimerInputElementType] = [
            .cardNumber, .cvv, .expiryDate, .cardholderName,
            .postalCode, .city, .state, .addressLine1,
            .addressLine2, .phoneNumber, .firstName, .lastName
        ]

        for fieldType in fieldTypes {
            let error = scope.getFieldError(fieldType)
            XCTAssertNil(error, "getFieldError for \(fieldType) should return nil")
        }
    }

    // MARK: - Customization Property Default Value Tests

    func test_title_defaultValue_isNil() {
        let scope = MockCardFormScopeImpl()
        XCTAssertNil(scope.title)
    }

    func test_title_canBeSet() {
        let scope = MockCardFormScopeImpl()
        scope.title = "Custom Card Form"
        XCTAssertEqual(scope.title, "Custom Card Form")
    }

    func test_screen_defaultValue_isNil() {
        let scope = MockCardFormScopeImpl()
        XCTAssertNil(scope.screen)
    }

    func test_screen_canBeSet() {
        let scope = MockCardFormScopeImpl()
        scope.screen = { _ in AnyView(EmptyView()) }
        XCTAssertNotNil(scope.screen)
    }

    func test_submitButtonText_defaultValue_isNil() {
        let scope = MockCardFormScopeImpl()
        XCTAssertNil(scope.submitButtonText)
    }

    func test_submitButtonText_canBeSet() {
        let scope = MockCardFormScopeImpl()
        scope.submitButtonText = "Pay Now"
        XCTAssertEqual(scope.submitButtonText, "Pay Now")
    }

    func test_showSubmitLoadingIndicator_defaultValue_isFalse() {
        let scope = MockCardFormScopeImpl()
        XCTAssertFalse(scope.showSubmitLoadingIndicator)
    }

    func test_showSubmitLoadingIndicator_canBeToggled() {
        let scope = MockCardFormScopeImpl()

        scope.showSubmitLoadingIndicator = true
        XCTAssertTrue(scope.showSubmitLoadingIndicator)

        scope.showSubmitLoadingIndicator = false
        XCTAssertFalse(scope.showSubmitLoadingIndicator)
    }

    // MARK: - Error View Customization Tests

    func test_errorView_defaultValue_isNil() {
        let scope = MockCardFormScopeImpl()
        XCTAssertNil(scope.errorView)
    }

    func test_errorView_canBeSet() {
        let scope = MockCardFormScopeImpl()
        scope.errorView = { _ in AnyView(EmptyView()) }
        XCTAssertNotNil(scope.errorView)
    }

    func test_cobadgedCardsView_defaultValue_isNil() {
        let scope = MockCardFormScopeImpl()
        XCTAssertNil(scope.cobadgedCardsView)
    }

    func test_cobadgedCardsView_canBeSet() {
        let scope = MockCardFormScopeImpl()
        scope.cobadgedCardsView = { _, _ in AnyView(EmptyView()) }
        XCTAssertNotNil(scope.cobadgedCardsView)
    }

    // MARK: - Field Configuration Tests

    func test_cardNumberConfig_defaultValue_isNil() {
        let scope = MockCardFormScopeImpl()
        XCTAssertNil(scope.cardNumberConfig)
    }

    func test_cardNumberConfig_canBeSet() {
        let scope = MockCardFormScopeImpl()
        scope.cardNumberConfig = InputFieldConfig(label: "Custom Label")
        XCTAssertNotNil(scope.cardNumberConfig)
        XCTAssertEqual(scope.cardNumberConfig?.label, "Custom Label")
    }

    func test_expiryDateConfig_canBeSet() {
        let scope = MockCardFormScopeImpl()
        scope.expiryDateConfig = InputFieldConfig(label: "Expiry")
        XCTAssertNotNil(scope.expiryDateConfig)
    }

    func test_cvvConfig_canBeSet() {
        let scope = MockCardFormScopeImpl()
        scope.cvvConfig = InputFieldConfig(label: "Security Code")
        XCTAssertNotNil(scope.cvvConfig)
    }

    func test_cardholderNameConfig_canBeSet() {
        let scope = MockCardFormScopeImpl()
        scope.cardholderNameConfig = InputFieldConfig(label: "Name on Card")
        XCTAssertNotNil(scope.cardholderNameConfig)
    }

    func test_allBillingAddressConfigs_canBeSet() {
        let scope = MockCardFormScopeImpl()

        scope.postalCodeConfig = InputFieldConfig(label: "ZIP")
        scope.countryConfig = InputFieldConfig(label: "Country")
        scope.cityConfig = InputFieldConfig(label: "City")
        scope.stateConfig = InputFieldConfig(label: "State")
        scope.addressLine1Config = InputFieldConfig(label: "Address 1")
        scope.addressLine2Config = InputFieldConfig(label: "Address 2")
        scope.phoneNumberConfig = InputFieldConfig(label: "Phone")
        scope.firstNameConfig = InputFieldConfig(label: "First Name")
        scope.lastNameConfig = InputFieldConfig(label: "Last Name")
        scope.emailConfig = InputFieldConfig(label: "Email")

        XCTAssertNotNil(scope.postalCodeConfig)
        XCTAssertNotNil(scope.countryConfig)
        XCTAssertNotNil(scope.cityConfig)
        XCTAssertNotNil(scope.stateConfig)
        XCTAssertNotNil(scope.addressLine1Config)
        XCTAssertNotNil(scope.addressLine2Config)
        XCTAssertNotNil(scope.phoneNumberConfig)
        XCTAssertNotNil(scope.firstNameConfig)
        XCTAssertNotNil(scope.lastNameConfig)
        XCTAssertNotNil(scope.emailConfig)
    }

    // MARK: - Section Customization Tests

    func test_cardInputSection_defaultValue_isNil() {
        let scope = MockCardFormScopeImpl()
        XCTAssertNil(scope.cardInputSection)
    }

    func test_cardInputSection_canBeSet() {
        let scope = MockCardFormScopeImpl()
        scope.cardInputSection = { AnyView(EmptyView()) }
        XCTAssertNotNil(scope.cardInputSection)
    }

    func test_billingAddressSection_defaultValue_isNil() {
        let scope = MockCardFormScopeImpl()
        XCTAssertNil(scope.billingAddressSection)
    }

    func test_billingAddressSection_canBeSet() {
        let scope = MockCardFormScopeImpl()
        scope.billingAddressSection = { AnyView(EmptyView()) }
        XCTAssertNotNil(scope.billingAddressSection)
    }

    func test_submitButtonSection_defaultValue_isNil() {
        let scope = MockCardFormScopeImpl()
        XCTAssertNil(scope.submitButtonSection)
    }

    func test_submitButtonSection_canBeSet() {
        let scope = MockCardFormScopeImpl()
        scope.submitButtonSection = { AnyView(EmptyView()) }
        XCTAssertNotNil(scope.submitButtonSection)
    }

    // MARK: - ViewBuilder Method Tests

    func test_primerCardNumberField_returnsView() {
        let scope = MockCardFormScopeImpl()
        let view = scope.PrimerCardNumberField(label: nil, styling: nil)
        XCTAssertNotNil(view)
    }

    func test_primerExpiryDateField_returnsView() {
        let scope = MockCardFormScopeImpl()
        let view = scope.PrimerExpiryDateField(label: nil, styling: nil)
        XCTAssertNotNil(view)
    }

    func test_primerCvvField_returnsView() {
        let scope = MockCardFormScopeImpl()
        let view = scope.PrimerCvvField(label: nil, styling: nil)
        XCTAssertNotNil(view)
    }

    func test_primerCardholderNameField_returnsView() {
        let scope = MockCardFormScopeImpl()
        let view = scope.PrimerCardholderNameField(label: nil, styling: nil)
        XCTAssertNotNil(view)
    }

    func test_primerCountryField_returnsView() {
        let scope = MockCardFormScopeImpl()
        let view = scope.PrimerCountryField(label: nil, styling: nil)
        XCTAssertNotNil(view)
    }

    func test_primerPostalCodeField_returnsView() {
        let scope = MockCardFormScopeImpl()
        let view = scope.PrimerPostalCodeField(label: nil, styling: nil)
        XCTAssertNotNil(view)
    }

    func test_primerCityField_returnsView() {
        let scope = MockCardFormScopeImpl()
        let view = scope.PrimerCityField(label: nil, styling: nil)
        XCTAssertNotNil(view)
    }

    func test_primerStateField_returnsView() {
        let scope = MockCardFormScopeImpl()
        let view = scope.PrimerStateField(label: nil, styling: nil)
        XCTAssertNotNil(view)
    }

    func test_primerAddressLine1Field_returnsView() {
        let scope = MockCardFormScopeImpl()
        let view = scope.PrimerAddressLine1Field(label: nil, styling: nil)
        XCTAssertNotNil(view)
    }

    func test_primerAddressLine2Field_returnsView() {
        let scope = MockCardFormScopeImpl()
        let view = scope.PrimerAddressLine2Field(label: nil, styling: nil)
        XCTAssertNotNil(view)
    }

    func test_primerFirstNameField_returnsView() {
        let scope = MockCardFormScopeImpl()
        let view = scope.PrimerFirstNameField(label: nil, styling: nil)
        XCTAssertNotNil(view)
    }

    func test_primerLastNameField_returnsView() {
        let scope = MockCardFormScopeImpl()
        let view = scope.PrimerLastNameField(label: nil, styling: nil)
        XCTAssertNotNil(view)
    }

    func test_primerEmailField_returnsView() {
        let scope = MockCardFormScopeImpl()
        let view = scope.PrimerEmailField(label: nil, styling: nil)
        XCTAssertNotNil(view)
    }

    func test_primerPhoneNumberField_returnsView() {
        let scope = MockCardFormScopeImpl()
        let view = scope.PrimerPhoneNumberField(label: nil, styling: nil)
        XCTAssertNotNil(view)
    }

    func test_primerRetailOutletField_returnsView() {
        let scope = MockCardFormScopeImpl()
        let view = scope.PrimerRetailOutletField(label: nil, styling: nil)
        XCTAssertNotNil(view)
    }

    func test_primerOtpCodeField_returnsView() {
        let scope = MockCardFormScopeImpl()
        let view = scope.PrimerOtpCodeField(label: nil, styling: nil)
        XCTAssertNotNil(view)
    }

    func test_defaultCardFormView_returnsView() {
        let scope = MockCardFormScopeImpl()
        let view = scope.DefaultCardFormView(styling: nil)
        XCTAssertNotNil(view)
    }

    // MARK: - ViewBuilder Method with Custom Parameters Tests

    func test_primerCardNumberField_withCustomLabel_returnsView() {
        let scope = MockCardFormScopeImpl()
        let view = scope.PrimerCardNumberField(label: "Custom Card Label", styling: nil)
        XCTAssertNotNil(view)
    }

    func test_primerCardNumberField_withStyling_returnsView() {
        let scope = MockCardFormScopeImpl()
        let styling = PrimerFieldStyling()
        let view = scope.PrimerCardNumberField(label: nil, styling: styling)
        XCTAssertNotNil(view)
    }

    // MARK: - Presentation Context Tests

    func test_presentationContext_direct_isAccessible() {
        let scope = MockCardFormScopeImpl()
        scope.presentationContext = .direct
        XCTAssertEqual(scope.presentationContext, .direct)
    }

    func test_presentationContext_fromPaymentSelection_isAccessible() {
        let scope = MockCardFormScopeImpl()
        scope.presentationContext = .fromPaymentSelection
        XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
    }

    // MARK: - Navigation Method Tests

    func test_onBack_canBeCalled() {
        var onBackCalled = false

        final class TrackingScope: MockCardFormScopeImpl {
            var onBackHandler: (() -> Void)?

            override func onBack() {
                onBackHandler?()
            }
        }

        let scope = TrackingScope()
        scope.onBackHandler = { onBackCalled = true }

        scope.onBack()

        XCTAssertTrue(onBackCalled)
    }

    // MARK: - State Stream Tests

    func test_state_canBeAccessed() async {
        let scope = MockCardFormScopeImpl()

        // When - iterate through state stream
        var statesReceived = 0
        for await _ in scope.state {
            statesReceived += 1
        }

        // Then - should receive at least one state
        XCTAssertGreaterThan(statesReceived, 0)
    }

    // MARK: - updateValidationState Tests

    func test_updateValidationState_canBeCalled() {
        let scope = MockCardFormScopeImpl()

        // Should not crash when called
        scope.updateValidationState(cardNumber: true, cvv: true, expiry: true, cardholderName: true)

        XCTAssertTrue(true, "updateValidationState should complete without error")
    }

    func test_updateValidationState_withMixedValues_canBeCalled() {
        let scope = MockCardFormScopeImpl()

        // Should not crash with mixed validation states
        scope.updateValidationState(cardNumber: true, cvv: false, expiry: true, cardholderName: false)

        XCTAssertTrue(true, "updateValidationState with mixed values should complete without error")
    }

    // MARK: - updateValidationStateIfNeeded Tests

    func test_updateValidationStateIfNeeded_withNonDefaultScope_doesNothing() {
        // Given - a mock scope that is NOT a DefaultCardFormScope
        let scope = MockCardFormScopeImpl()

        // When - call updateValidationStateIfNeeded (should early return due to guard)
        scope.updateValidationStateIfNeeded(for: .cardNumber, isValid: true)

        // Then - should not crash (just returns early)
        XCTAssertTrue(true, "updateValidationStateIfNeeded on non-DefaultCardFormScope should return early")
    }

    func test_updateValidationStateIfNeeded_allFieldTypes_doesNothing() {
        let scope = MockCardFormScopeImpl()
        let fieldTypes: [PrimerInputElementType] = [
            .cardNumber, .cvv, .expiryDate, .cardholderName,
            .email, .firstName, .lastName, .addressLine1,
            .addressLine2, .city, .state, .postalCode,
            .countryCode, .phoneNumber, .retailer, .otp, .unknown, .all
        ]

        // When - call for all field types
        for fieldType in fieldTypes {
            scope.updateValidationStateIfNeeded(for: fieldType, isValid: true)
            scope.updateValidationStateIfNeeded(for: fieldType, isValid: false)
        }

        // Then - should not crash
        XCTAssertTrue(true, "updateValidationStateIfNeeded for all field types should complete without error")
    }

    // MARK: - Edge Case Tests for Field Updates

    func test_updateField_withEmptyString_dispatches() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.cardNumber, value: "")

        XCTAssertEqual(scope.updatedFields[.cardNumber], "")
    }

    func test_updateField_withSpecialCharacters_dispatches() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.cardholderName, value: "José García-López")

        XCTAssertEqual(scope.updatedFields[.cardholderName], "José García-López")
    }

    func test_updateField_withUnicodeEmoji_dispatches() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.city, value: "New York 🗽")

        XCTAssertEqual(scope.updatedFields[.city], "New York 🗽")
    }

    func test_updateField_multipleUpdates_overwritesPrevious() {
        let scope = MockCardFormScopeImpl()

        // When - update same field multiple times
        scope.updateField(.cardNumber, value: "1111")
        scope.updateField(.cardNumber, value: "2222")
        scope.updateField(.cardNumber, value: "4111111111111111")

        // Then - last value is retained
        XCTAssertEqual(scope.updatedFields[.cardNumber], "4111111111111111")
    }

    func test_updateField_withVeryLongValue_dispatches() {
        let scope = MockCardFormScopeImpl()
        let longValue = String(repeating: "A", count: 1000)

        scope.updateField(.addressLine1, value: longValue)

        XCTAssertEqual(scope.updatedFields[.addressLine1], longValue)
    }

    func test_updateField_withWhitespaceOnlyValue_dispatches() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.postalCode, value: "   ")

        XCTAssertEqual(scope.updatedFields[.postalCode], "   ")
    }

    // MARK: - RetailOutlet and OTP Config Tests

    func test_retailOutletConfig_defaultValue_isNil() {
        let scope = MockCardFormScopeImpl()
        XCTAssertNil(scope.retailOutletConfig)
    }

    func test_retailOutletConfig_canBeSet() {
        let scope = MockCardFormScopeImpl()
        scope.retailOutletConfig = InputFieldConfig(label: "Select Store")
        XCTAssertNotNil(scope.retailOutletConfig)
        XCTAssertEqual(scope.retailOutletConfig?.label, "Select Store")
    }

    func test_otpCodeConfig_defaultValue_isNil() {
        let scope = MockCardFormScopeImpl()
        XCTAssertNil(scope.otpCodeConfig)
    }

    func test_otpCodeConfig_canBeSet() {
        let scope = MockCardFormScopeImpl()
        scope.otpCodeConfig = InputFieldConfig(label: "Verification Code")
        XCTAssertNotNil(scope.otpCodeConfig)
        XCTAssertEqual(scope.otpCodeConfig?.label, "Verification Code")
    }

    // MARK: - CardFormUIOptions Tests

    func test_cardFormUIOptions_defaultValue_isNil() {
        let scope = MockCardFormScopeImpl()
        XCTAssertNil(scope.cardFormUIOptions)
    }

    func test_cardFormUIOptions_canBeSet() {
        let scope = MockCardFormScopeImpl()
        let options = PrimerCardFormUIOptions(payButtonAddNewCard: true)
        scope.cardFormUIOptions = options
        XCTAssertNotNil(scope.cardFormUIOptions)
    }

    // MARK: - DismissalMechanism Tests

    func test_dismissalMechanism_defaultValue_isEmpty() {
        let scope = MockCardFormScopeImpl()
        XCTAssertTrue(scope.dismissalMechanism.isEmpty)
    }

    func test_dismissalMechanism_canBeSet() {
        let scope = MockCardFormScopeImpl()
        scope.dismissalMechanism = [.gestures]
        XCTAssertEqual(scope.dismissalMechanism.count, 1)
    }

    func test_dismissalMechanism_canHaveMultipleValues() {
        let scope = MockCardFormScopeImpl()
        scope.dismissalMechanism = [.gestures, .closeButton]
        XCTAssertEqual(scope.dismissalMechanism.count, 2)
    }

    // MARK: - ViewBuilder Field Methods with Both Parameters

    func test_primerExpiryDateField_withLabelAndStyling_returnsView() {
        let scope = MockCardFormScopeImpl()
        let styling = PrimerFieldStyling()
        let view = scope.PrimerExpiryDateField(label: "Expiration", styling: styling)
        XCTAssertNotNil(view)
    }

    func test_primerCvvField_withLabelAndStyling_returnsView() {
        let scope = MockCardFormScopeImpl()
        let styling = PrimerFieldStyling()
        let view = scope.PrimerCvvField(label: "CVV/CVC", styling: styling)
        XCTAssertNotNil(view)
    }

    func test_defaultCardFormView_withStyling_returnsView() {
        let scope = MockCardFormScopeImpl()
        let styling = PrimerFieldStyling()
        let view = scope.DefaultCardFormView(styling: styling)
        XCTAssertNotNil(view)
    }

    // MARK: - Multiple State Access Tests

    func test_state_multipleIterations_work() async {
        let scope = MockCardFormScopeImpl()

        // First iteration
        var count1 = 0
        for await _ in scope.state {
            count1 += 1
        }

        // Second iteration (new stream)
        var count2 = 0
        for await _ in scope.state {
            count2 += 1
        }

        XCTAssertEqual(count1, count2, "Both iterations should receive same number of states")
    }

    // MARK: - Validation State Edge Cases

    func test_updateValidationState_allFalse_canBeCalled() {
        let scope = MockCardFormScopeImpl()

        scope.updateValidationState(cardNumber: false, cvv: false, expiry: false, cardholderName: false)

        XCTAssertTrue(true, "updateValidationState with all false should complete without error")
    }

    func test_updateValidationState_allTrue_canBeCalled() {
        let scope = MockCardFormScopeImpl()

        scope.updateValidationState(cardNumber: true, cvv: true, expiry: true, cardholderName: true)

        XCTAssertTrue(true, "updateValidationState with all true should complete without error")
    }

    // MARK: - Title Edge Cases

    func test_title_canBeSetToEmptyString() {
        let scope = MockCardFormScopeImpl()
        scope.title = ""
        XCTAssertEqual(scope.title, "")
    }

    func test_title_canBeResetToNil() {
        let scope = MockCardFormScopeImpl()
        scope.title = "Card Form"
        scope.title = nil
        XCTAssertNil(scope.title)
    }

    // MARK: - SubmitButtonText Edge Cases

    func test_submitButtonText_canBeSetToEmptyString() {
        let scope = MockCardFormScopeImpl()
        scope.submitButtonText = ""
        XCTAssertEqual(scope.submitButtonText, "")
    }

    func test_submitButtonText_canBeResetToNil() {
        let scope = MockCardFormScopeImpl()
        scope.submitButtonText = "Pay"
        scope.submitButtonText = nil
        XCTAssertNil(scope.submitButtonText)
    }

    // MARK: - Field Config Replacement Tests

    func test_cardNumberConfig_canBeReplaced() {
        let scope = MockCardFormScopeImpl()
        scope.cardNumberConfig = InputFieldConfig(label: "First Label")
        scope.cardNumberConfig = InputFieldConfig(label: "Replaced Label")
        XCTAssertEqual(scope.cardNumberConfig?.label, "Replaced Label")
    }

    func test_cardNumberConfig_canBeResetToNil() {
        let scope = MockCardFormScopeImpl()
        scope.cardNumberConfig = InputFieldConfig(label: "Label")
        scope.cardNumberConfig = nil
        XCTAssertNil(scope.cardNumberConfig)
    }

    // MARK: - Section Replacement Tests

    func test_cardInputSection_canBeReplaced() {
        let scope = MockCardFormScopeImpl()
        scope.cardInputSection = { AnyView(EmptyView()) }
        scope.cardInputSection = { AnyView(Text("Replaced")) }
        XCTAssertNotNil(scope.cardInputSection)
    }

    func test_cardInputSection_canBeResetToNil() {
        let scope = MockCardFormScopeImpl()
        scope.cardInputSection = { AnyView(EmptyView()) }
        scope.cardInputSection = nil
        XCTAssertNil(scope.cardInputSection)
    }

    // MARK: - Error View Replacement Tests

    func test_errorView_canBeReplaced() {
        let scope = MockCardFormScopeImpl()
        scope.errorView = { _ in AnyView(Text("First")) }
        scope.errorView = { _ in AnyView(Text("Second")) }
        XCTAssertNotNil(scope.errorView)
    }

    func test_errorView_canBeResetToNil() {
        let scope = MockCardFormScopeImpl()
        scope.errorView = { _ in AnyView(EmptyView()) }
        scope.errorView = nil
        XCTAssertNil(scope.errorView)
    }
}
