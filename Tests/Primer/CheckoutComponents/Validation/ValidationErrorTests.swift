//
//  ValidationErrorTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for ValidationError struct.
@available(iOS 15.0, *)
final class ValidationErrorTests: XCTestCase {

    // MARK: - Full Initializer Tests

    func test_init_withAllParameters_setsAllProperties() {
        // Given/When
        let error = ValidationError(
            inputElementType: .cardNumber,
            errorId: "error-123",
            fieldNameKey: "field.cardNumber",
            errorMessageKey: "error.invalid",
            errorFormatKey: "error.format",
            code: "INVALID_CARD",
            message: "Card number is invalid"
        )

        // Then
        XCTAssertEqual(error.inputElementType, .cardNumber)
        XCTAssertEqual(error.errorId, "error-123")
        XCTAssertEqual(error.fieldNameKey, "field.cardNumber")
        XCTAssertEqual(error.errorMessageKey, "error.invalid")
        XCTAssertEqual(error.errorFormatKey, "error.format")
        XCTAssertEqual(error.code, "INVALID_CARD")
        XCTAssertEqual(error.message, "Card number is invalid")
    }

    func test_init_withNilOptionalParameters_setsNilValues() {
        // Given/When
        let error = ValidationError(
            inputElementType: .cvv,
            errorId: "cvv-error",
            fieldNameKey: nil,
            errorMessageKey: nil,
            errorFormatKey: nil,
            code: "CVV_REQUIRED",
            message: "CVV is required"
        )

        // Then
        XCTAssertNil(error.fieldNameKey)
        XCTAssertNil(error.errorMessageKey)
        XCTAssertNil(error.errorFormatKey)
    }

    // MARK: - Simple Initializer Tests

    func test_simpleInit_setsCodeAndMessage() {
        // Given/When
        let error = ValidationError(code: "TEST_ERROR", message: "Test error message")

        // Then
        XCTAssertEqual(error.code, "TEST_ERROR")
        XCTAssertEqual(error.message, "Test error message")
    }

    func test_simpleInit_setsDefaultInputElementType() {
        // Given/When
        let error = ValidationError(code: "ERROR", message: "Message")

        // Then
        XCTAssertEqual(error.inputElementType, .unknown)
    }

    func test_simpleInit_setsErrorIdFromCode() {
        // Given/When
        let error = ValidationError(code: "MY_ERROR_CODE", message: "Message")

        // Then
        XCTAssertEqual(error.errorId, "MY_ERROR_CODE")
    }

    func test_simpleInit_setsNilLocalizationKeys() {
        // Given/When
        let error = ValidationError(code: "ERROR", message: "Message")

        // Then
        XCTAssertNil(error.fieldNameKey)
        XCTAssertNil(error.errorMessageKey)
        XCTAssertNil(error.errorFormatKey)
    }

    // MARK: - InputElementType Tests

    func test_inputElementType_cardNumber_hasCorrectRawValue() {
        XCTAssertEqual(ValidationError.InputElementType.cardNumber.rawValue, "CARD_NUMBER")
    }

    func test_inputElementType_cvv_hasCorrectRawValue() {
        XCTAssertEqual(ValidationError.InputElementType.cvv.rawValue, "CVV")
    }

    func test_inputElementType_expiryDate_hasCorrectRawValue() {
        XCTAssertEqual(ValidationError.InputElementType.expiryDate.rawValue, "EXPIRY_DATE")
    }

    func test_inputElementType_cardholderName_hasCorrectRawValue() {
        XCTAssertEqual(ValidationError.InputElementType.cardholderName.rawValue, "CARDHOLDER_NAME")
    }

    func test_inputElementType_firstName_hasCorrectRawValue() {
        XCTAssertEqual(ValidationError.InputElementType.firstName.rawValue, "FIRST_NAME")
    }

    func test_inputElementType_lastName_hasCorrectRawValue() {
        XCTAssertEqual(ValidationError.InputElementType.lastName.rawValue, "LAST_NAME")
    }

    func test_inputElementType_email_hasCorrectRawValue() {
        XCTAssertEqual(ValidationError.InputElementType.email.rawValue, "EMAIL")
    }

    func test_inputElementType_phoneNumber_hasCorrectRawValue() {
        XCTAssertEqual(ValidationError.InputElementType.phoneNumber.rawValue, "PHONE_NUMBER")
    }

    func test_inputElementType_addressLine1_hasCorrectRawValue() {
        XCTAssertEqual(ValidationError.InputElementType.addressLine1.rawValue, "ADDRESS_LINE_1")
    }

    func test_inputElementType_addressLine2_hasCorrectRawValue() {
        XCTAssertEqual(ValidationError.InputElementType.addressLine2.rawValue, "ADDRESS_LINE_2")
    }

    func test_inputElementType_city_hasCorrectRawValue() {
        XCTAssertEqual(ValidationError.InputElementType.city.rawValue, "CITY")
    }

    func test_inputElementType_state_hasCorrectRawValue() {
        XCTAssertEqual(ValidationError.InputElementType.state.rawValue, "STATE")
    }

    func test_inputElementType_postalCode_hasCorrectRawValue() {
        XCTAssertEqual(ValidationError.InputElementType.postalCode.rawValue, "POSTAL_CODE")
    }

    func test_inputElementType_countryCode_hasCorrectRawValue() {
        XCTAssertEqual(ValidationError.InputElementType.countryCode.rawValue, "COUNTRY_CODE")
    }

    func test_inputElementType_retailOutlet_hasCorrectRawValue() {
        XCTAssertEqual(ValidationError.InputElementType.retailOutlet.rawValue, "RETAIL_OUTLET")
    }

    func test_inputElementType_otpCode_hasCorrectRawValue() {
        XCTAssertEqual(ValidationError.InputElementType.otpCode.rawValue, "OTP_CODE")
    }

    func test_inputElementType_unknown_hasCorrectRawValue() {
        XCTAssertEqual(ValidationError.InputElementType.unknown.rawValue, "UNKNOWN")
    }

    func test_inputElementType_allCases_contains17Types() {
        XCTAssertEqual(ValidationError.InputElementType.allCases.count, 17)
    }

    // MARK: - Equatable Tests

    func test_equatable_sameValues_areEqual() {
        // Given
        let error1 = ValidationError(code: "ERROR", message: "Message")
        let error2 = ValidationError(code: "ERROR", message: "Message")

        // Then
        XCTAssertEqual(error1, error2)
    }

    func test_equatable_differentCodes_areNotEqual() {
        // Given
        let error1 = ValidationError(code: "ERROR1", message: "Message")
        let error2 = ValidationError(code: "ERROR2", message: "Message")

        // Then
        XCTAssertNotEqual(error1, error2)
    }

    func test_equatable_differentMessages_areNotEqual() {
        // Given
        let error1 = ValidationError(code: "ERROR", message: "Message1")
        let error2 = ValidationError(code: "ERROR", message: "Message2")

        // Then
        XCTAssertNotEqual(error1, error2)
    }

    // MARK: - Hashable Tests

    func test_hashable_sameValues_haveSameHash() {
        // Given
        let error1 = ValidationError(code: "ERROR", message: "Message")
        let error2 = ValidationError(code: "ERROR", message: "Message")

        // Then
        XCTAssertEqual(error1.hashValue, error2.hashValue)
    }

    func test_hashable_canBeUsedInSet() {
        // Given
        let error1 = ValidationError(code: "ERROR1", message: "Message1")
        let error2 = ValidationError(code: "ERROR2", message: "Message2")
        let error3 = ValidationError(code: "ERROR1", message: "Message1") // Duplicate

        // When
        let errorSet: Set<ValidationError> = [error1, error2, error3]

        // Then
        XCTAssertEqual(errorSet.count, 2)
    }
}
