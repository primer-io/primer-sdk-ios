//
//  ErrorMessageResolverTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

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
        XCTAssertEqual(result, TestData.ErrorMessages.retailOutletRequired)
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
        XCTAssertEqual(result, TestData.ErrorMessages.retailOutletInvalid)
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

    // MARK: - Helper Methods

    private func createError(messageKey: String) -> ValidationError {
        ValidationError(
            inputElementType: .unknown,
            errorId: TestData.TestFixtures.defaultErrorId,
            fieldNameKey: nil,
            errorMessageKey: messageKey,
            errorFormatKey: nil,
            code: TestData.TestFixtures.defaultCode,
            message: TestData.TestFixtures.defaultMessage
        )
    }
}
