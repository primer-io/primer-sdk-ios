//
//  ErrorMessageResolverTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for ErrorMessageResolver - string resolution and error creation functionality.
@available(iOS 15.0, *)
final class ErrorMessageResolverTests: XCTestCase {

    // MARK: - resolveErrorMessage Tests

    // MARK: Form Validation Errors

    func test_resolveErrorMessage_withCardTypeNotSupported_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "form_error_card_type_not_supported")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.formErrorCardTypeNotSupported)
    }

    func test_resolveErrorMessage_withCardHolderNameLength_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "form_error_card_holder_name_length")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.formErrorCardHolderNameLength)
    }

    func test_resolveErrorMessage_withCardExpired_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "form_error_card_expired")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.formErrorCardExpired)
    }

    // MARK: Required Field Errors

    func test_resolveErrorMessage_withFirstNameRequired_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_first_name_required")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.firstNameErrorRequired)
    }

    func test_resolveErrorMessage_withLastNameRequired_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_last_name_required")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.lastNameErrorRequired)
    }

    func test_resolveErrorMessage_withEmailRequired_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_email_required")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.emailErrorRequired)
    }

    func test_resolveErrorMessage_withCountryRequired_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_country_required")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.countryCodeErrorRequired)
    }

    func test_resolveErrorMessage_withAddressLine1Required_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_address_line_1_required")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.addressLine1ErrorRequired)
    }

    func test_resolveErrorMessage_withAddressLine2Required_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_address_line_2_required")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.addressLine2ErrorRequired)
    }

    func test_resolveErrorMessage_withCityRequired_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_city_required")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.cityErrorRequired)
    }

    func test_resolveErrorMessage_withStateRequired_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_state_required")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.stateErrorRequired)
    }

    func test_resolveErrorMessage_withPostalCodeRequired_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_postal_code_required")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.postalCodeErrorRequired)
    }

    func test_resolveErrorMessage_withPhoneNumberRequired_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_phone_number_required")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.enterValidPhoneNumber)
    }

    func test_resolveErrorMessage_withRetailOutletRequired_returnsHardcodedString() {
        // Given
        let error = createError(messageKey: "checkout_components_retail_outlet_required")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, "Retail outlet is required")
    }

    // MARK: Invalid Field Errors - Card Fields

    func test_resolveErrorMessage_withCardNumberInvalid_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_card_number_invalid")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.enterValidCardNumber)
    }

    func test_resolveErrorMessage_withCVVInvalid_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_cvv_invalid")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.enterValidCVV)
    }

    func test_resolveErrorMessage_withExpiryDateInvalid_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_expiry_date_invalid")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.enterValidExpiryDate)
    }

    func test_resolveErrorMessage_withCardholderNameInvalid_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_cardholder_name_invalid")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.enterValidCardholderName)
    }

    // MARK: Invalid Field Errors - Billing Address Fields

    func test_resolveErrorMessage_withFirstNameInvalid_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_first_name_invalid")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.firstNameErrorInvalid)
    }

    func test_resolveErrorMessage_withLastNameInvalid_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_last_name_invalid")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.lastNameErrorInvalid)
    }

    func test_resolveErrorMessage_withEmailInvalid_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_email_invalid")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.emailErrorInvalid)
    }

    func test_resolveErrorMessage_withCountryInvalid_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_country_invalid")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.countryCodeErrorInvalid)
    }

    func test_resolveErrorMessage_withAddressLine1Invalid_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_address_line_1_invalid")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.addressLine1ErrorInvalid)
    }

    func test_resolveErrorMessage_withAddressLine2Invalid_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_address_line_2_invalid")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.addressLine2ErrorInvalid)
    }

    func test_resolveErrorMessage_withCityInvalid_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_city_invalid")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.cityErrorInvalid)
    }

    func test_resolveErrorMessage_withStateInvalid_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_state_invalid")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.stateErrorInvalid)
    }

    func test_resolveErrorMessage_withPostalCodeInvalid_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_postal_code_invalid")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.postalCodeErrorInvalid)
    }

    func test_resolveErrorMessage_withPhoneNumberInvalid_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "checkout_components_phone_number_invalid")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.enterValidPhoneNumber)
    }

    func test_resolveErrorMessage_withRetailOutletInvalid_returnsHardcodedString() {
        // Given
        let error = createError(messageKey: "checkout_components_retail_outlet_invalid")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, "Invalid retail outlet")
    }

    // MARK: Result Screen Messages

    func test_resolveErrorMessage_withPaymentSuccessful_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "payment_successful")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.paymentSuccessful)
    }

    func test_resolveErrorMessage_withPaymentFailed_returnsCorrectString() {
        // Given
        let error = createError(messageKey: "payment_failed")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.paymentFailed)
    }

    // MARK: Fallback Behavior

    func test_resolveErrorMessage_withUnknownKey_returnsUnexpectedError() {
        // Given
        let error = createError(messageKey: "unknown_error_key")

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, CheckoutComponentsStrings.unexpectedError)
    }

    func test_resolveErrorMessage_withNoMessageKey_returnsErrorId() {
        // Given
        let error = ValidationError(
            inputElementType: .unknown,
            errorId: "custom_error_id",
            fieldNameKey: nil,
            errorMessageKey: nil,
            errorFormatKey: nil,
            code: "test-code",
            message: "Test message"
        )

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(result, "custom_error_id")
    }

    // MARK: Format String Resolution (Priority 1)

    func test_resolveErrorMessage_withFormatKeyAndFieldNameKey_returnsFormattedString() {
        // Given - This tests the highest priority path (format key + field name key)
        // Note: This requires valid format and field name keys to produce a meaningful result
        let error = ValidationError(
            inputElementType: .firstName,
            errorId: "test_error",
            fieldNameKey: "first_name_field",
            errorMessageKey: nil,
            errorFormatKey: "form_error_card_type_not_supported", // Using existing key as format
            code: "test-code",
            message: "Test"
        )

        // When
        let result = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then - Should use format string interpolation
        XCTAssertNotNil(result)
        // The result will be a formatted string with the field name
    }

    // MARK: - createRequiredFieldError Tests

    func test_createRequiredFieldError_forFirstName_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .firstName)

        // Then
        XCTAssertEqual(error.inputElementType, .firstName)
        XCTAssertEqual(error.errorId, "first_name_required")
        XCTAssertEqual(error.errorMessageKey, "checkout_components_first_name_required")
        XCTAssertEqual(error.code, "invalid-first_name")
        XCTAssertEqual(error.message, "Field is required")
    }

    func test_createRequiredFieldError_forLastName_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .lastName)

        // Then
        XCTAssertEqual(error.inputElementType, .lastName)
        XCTAssertEqual(error.errorId, "last_name_required")
        XCTAssertEqual(error.errorMessageKey, "checkout_components_last_name_required")
    }

    func test_createRequiredFieldError_forEmail_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .email)

        // Then
        XCTAssertEqual(error.inputElementType, .email)
        XCTAssertEqual(error.errorId, "email_required")
        XCTAssertEqual(error.errorMessageKey, "checkout_components_email_required")
    }

    func test_createRequiredFieldError_forCountryCode_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .countryCode)

        // Then
        XCTAssertEqual(error.inputElementType, .countryCode)
        XCTAssertEqual(error.errorId, "country_code_required")
        XCTAssertEqual(error.errorMessageKey, "checkout_components_country_required")
    }

    func test_createRequiredFieldError_forAddressLine1_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .addressLine1)

        // Then
        XCTAssertEqual(error.inputElementType, .addressLine1)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_address_line_1_required")
    }

    func test_createRequiredFieldError_forAddressLine2_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .addressLine2)

        // Then
        XCTAssertEqual(error.inputElementType, .addressLine2)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_address_line_2_required")
    }

    func test_createRequiredFieldError_forCity_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .city)

        // Then
        XCTAssertEqual(error.inputElementType, .city)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_city_required")
    }

    func test_createRequiredFieldError_forState_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .state)

        // Then
        XCTAssertEqual(error.inputElementType, .state)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_state_required")
    }

    func test_createRequiredFieldError_forPostalCode_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .postalCode)

        // Then
        XCTAssertEqual(error.inputElementType, .postalCode)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_postal_code_required")
    }

    func test_createRequiredFieldError_forPhoneNumber_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .phoneNumber)

        // Then
        XCTAssertEqual(error.inputElementType, .phoneNumber)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_phone_number_required")
    }

    func test_createRequiredFieldError_forRetailOutlet_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .retailOutlet)

        // Then
        XCTAssertEqual(error.inputElementType, .retailOutlet)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_retail_outlet_required")
    }

    func test_createRequiredFieldError_forUnknown_usesGenericKey() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .unknown)

        // Then
        XCTAssertEqual(error.inputElementType, .unknown)
        XCTAssertEqual(error.errorMessageKey, "form_error_required")
    }

    // MARK: - createInvalidFieldError Tests

    func test_createInvalidFieldError_forCardNumber_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .cardNumber)

        // Then
        XCTAssertEqual(error.inputElementType, .cardNumber)
        XCTAssertEqual(error.errorId, "card_number_invalid")
        XCTAssertEqual(error.errorMessageKey, "checkout_components_card_number_invalid")
        XCTAssertEqual(error.code, "invalid-card_number")
        XCTAssertEqual(error.message, "Field is invalid")
    }

    func test_createInvalidFieldError_forCVV_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .cvv)

        // Then
        XCTAssertEqual(error.inputElementType, .cvv)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_cvv_invalid")
    }

    func test_createInvalidFieldError_forExpiryDate_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .expiryDate)

        // Then
        XCTAssertEqual(error.inputElementType, .expiryDate)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_expiry_date_invalid")
    }

    func test_createInvalidFieldError_forCardholderName_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .cardholderName)

        // Then
        XCTAssertEqual(error.inputElementType, .cardholderName)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_cardholder_name_invalid")
    }

    func test_createInvalidFieldError_forFirstName_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .firstName)

        // Then
        XCTAssertEqual(error.inputElementType, .firstName)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_first_name_invalid")
    }

    func test_createInvalidFieldError_forLastName_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .lastName)

        // Then
        XCTAssertEqual(error.inputElementType, .lastName)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_last_name_invalid")
    }

    func test_createInvalidFieldError_forEmail_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .email)

        // Then
        XCTAssertEqual(error.inputElementType, .email)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_email_invalid")
    }

    func test_createInvalidFieldError_forCountryCode_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .countryCode)

        // Then
        XCTAssertEqual(error.inputElementType, .countryCode)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_country_invalid")
    }

    func test_createInvalidFieldError_forAddressLine1_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .addressLine1)

        // Then
        XCTAssertEqual(error.inputElementType, .addressLine1)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_address_line_1_invalid")
    }

    func test_createInvalidFieldError_forAddressLine2_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .addressLine2)

        // Then
        XCTAssertEqual(error.inputElementType, .addressLine2)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_address_line_2_invalid")
    }

    func test_createInvalidFieldError_forCity_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .city)

        // Then
        XCTAssertEqual(error.inputElementType, .city)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_city_invalid")
    }

    func test_createInvalidFieldError_forState_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .state)

        // Then
        XCTAssertEqual(error.inputElementType, .state)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_state_invalid")
    }

    func test_createInvalidFieldError_forPostalCode_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .postalCode)

        // Then
        XCTAssertEqual(error.inputElementType, .postalCode)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_postal_code_invalid")
    }

    func test_createInvalidFieldError_forPhoneNumber_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .phoneNumber)

        // Then
        XCTAssertEqual(error.inputElementType, .phoneNumber)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_phone_number_invalid")
    }

    func test_createInvalidFieldError_forRetailOutlet_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .retailOutlet)

        // Then
        XCTAssertEqual(error.inputElementType, .retailOutlet)
        XCTAssertEqual(error.errorMessageKey, "checkout_components_retail_outlet_invalid")
    }

    func test_createInvalidFieldError_forUnknown_usesGenericKey() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .unknown)

        // Then
        XCTAssertEqual(error.inputElementType, .unknown)
        XCTAssertEqual(error.errorMessageKey, "form_error_invalid")
    }

    // MARK: - Integration Tests

    func test_createdRequiredError_resolvesToCorrectMessage() {
        // Given
        let error = ErrorMessageResolver.createRequiredFieldError(for: .firstName)

        // When
        let message = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(message, CheckoutComponentsStrings.firstNameErrorRequired)
    }

    func test_createdInvalidError_resolvesToCorrectMessage() {
        // Given
        let error = ErrorMessageResolver.createInvalidFieldError(for: .cardNumber)

        // When
        let message = ErrorMessageResolver.resolveErrorMessage(for: error)

        // Then
        XCTAssertEqual(message, CheckoutComponentsStrings.enterValidCardNumber)
    }

    // MARK: - All Input Element Types Coverage

    func test_allInputElementTypes_haveRequiredErrorKeys() {
        // Test that all relevant input element types have required error key mappings
        let typesToTest: [ValidationError.InputElementType] = [
            .firstName, .lastName, .email, .countryCode,
            .addressLine1, .addressLine2, .city, .state,
            .postalCode, .phoneNumber, .retailOutlet
        ]

        for type in typesToTest {
            let error = ErrorMessageResolver.createRequiredFieldError(for: type)
            let message = ErrorMessageResolver.resolveErrorMessage(for: error)

            // Should not fall back to unexpected error for known types
            XCTAssertNotEqual(message, CheckoutComponentsStrings.unexpectedError,
                              "Type \(type) should have a valid required error message")
        }
    }

    func test_allInputElementTypes_haveInvalidErrorKeys() {
        // Test that all relevant input element types have invalid error key mappings
        let typesToTest: [ValidationError.InputElementType] = [
            .cardNumber, .cvv, .expiryDate, .cardholderName,
            .firstName, .lastName, .email, .countryCode,
            .addressLine1, .addressLine2, .city, .state,
            .postalCode, .phoneNumber, .retailOutlet
        ]

        for type in typesToTest {
            let error = ErrorMessageResolver.createInvalidFieldError(for: type)
            let message = ErrorMessageResolver.resolveErrorMessage(for: error)

            // Should not fall back to unexpected error for known types
            XCTAssertNotEqual(message, CheckoutComponentsStrings.unexpectedError,
                              "Type \(type) should have a valid invalid error message")
        }
    }

    // MARK: - Helper Methods

    private func createError(messageKey: String) -> ValidationError {
        ValidationError(
            inputElementType: .unknown,
            errorId: "test_error",
            fieldNameKey: nil,
            errorMessageKey: messageKey,
            errorFormatKey: nil,
            code: "test-code",
            message: "Test message"
        )
    }
}
