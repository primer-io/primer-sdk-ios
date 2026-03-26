//
//  ValidationResultTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class ValidationResultTests: XCTestCase {

    // MARK: - Invalid(code:message:) Tests

    func test_invalidWithCodeAndMessage_setsErrorCode() {
        // When
        let result = ValidationResult.invalid(code: "TEST_ERROR", message: "Test error message")

        // Then
        XCTAssertEqual(result.errorCode, "TEST_ERROR")
    }

    func test_invalidWithCodeAndMessage_setsErrorMessage() {
        // When
        let result = ValidationResult.invalid(code: "TEST_ERROR", message: "Test error message")

        // Then
        XCTAssertEqual(result.errorMessage, "Test error message")
    }

    func test_invalidWithCodeAndMessage_preservesEmptyStrings() {
        // When
        let result = ValidationResult.invalid(code: "", message: "")

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorCode, "")
        XCTAssertEqual(result.errorMessage, "")
    }

    // MARK: - Invalid(error:) Tests

    func test_invalidWithError_setsErrorCodeFromError() {
        // Given
        let error = ValidationError(code: "VALIDATION_ERROR", message: "Validation failed")

        // When
        let result = ValidationResult.invalid(error: error)

        // Then
        XCTAssertEqual(result.errorCode, "VALIDATION_ERROR")
    }

    func test_invalidWithError_setsErrorMessageFromError() {
        // Given
        let error = ValidationError(code: "VALIDATION_ERROR", message: "Validation failed")

        // When
        let result = ValidationResult.invalid(error: error)

        // Then
        // Message may be resolved or fall back to error.message
        XCTAssertNotNil(result.errorMessage)
    }

    func test_invalidWithError_withFullValidationError_preservesCode() {
        // Given
        let error = ValidationError(
            inputElementType: .cardNumber,
            errorId: "card_number_invalid",
            fieldNameKey: "field.cardNumber",
            errorMessageKey: "error.cardNumber.invalid",
            errorFormatKey: nil,
            code: "CARD_NUMBER_INVALID",
            message: "Card number is invalid"
        )

        // When
        let result = ValidationResult.invalid(error: error)

        // Then
        XCTAssertEqual(result.errorCode, "CARD_NUMBER_INVALID")
    }

    // MARK: - toValidationError Tests

    func test_toValidationError_whenValid_returnsNil() {
        // Given
        let result = ValidationResult.valid

        // When
        let error = result.toValidationError

        // Then
        XCTAssertNil(error)
    }

    func test_toValidationError_whenInvalid_returnsValidationError() {
        // Given
        let result = ValidationResult.invalid(code: "TEST_ERROR", message: "Test message")

        // When
        let error = result.toValidationError

        // Then
        XCTAssertNotNil(error)
    }

    func test_toValidationError_whenInvalid_errorHasCorrectCode() {
        // Given
        let result = ValidationResult.invalid(code: "TEST_ERROR", message: "Test message")

        // When
        let error = result.toValidationError

        // Then
        XCTAssertEqual(error?.code, "TEST_ERROR")
    }

    func test_toValidationError_whenInvalid_errorHasCorrectMessage() {
        // Given
        let result = ValidationResult.invalid(code: "TEST_ERROR", message: "Test message")

        // When
        let error = result.toValidationError

        // Then
        XCTAssertEqual(error?.message, "Test message")
    }

    func test_toValidationError_whenInvalidWithNilErrorCode_returnsNil() {
        // Given - create result that is invalid but has nil errorCode
        // This tests the guard condition
        let result = ValidationResult(isValid: false, errorCode: nil, errorMessage: "Some message")

        // When
        let error = result.toValidationError

        // Then
        XCTAssertNil(error)
    }

    func test_toValidationError_whenInvalidWithNilErrorMessage_returnsNil() {
        // Given - create result that is invalid but has nil errorMessage
        // This tests the guard condition
        let result = ValidationResult(isValid: false, errorCode: "CODE", errorMessage: nil)

        // When
        let error = result.toValidationError

        // Then
        XCTAssertNil(error)
    }

    // MARK: - Edge Case Tests

    func test_invalid_withSpecialCharactersInCode() {
        // Given
        let code = "ERROR-123_ABC.test"
        let message = "Error with special chars: <>&\""

        // When
        let result = ValidationResult.invalid(code: code, message: message)

        // Then
        XCTAssertEqual(result.errorCode, code)
        XCTAssertEqual(result.errorMessage, message)
    }

    func test_invalid_withUnicodeInMessage() {
        // Given
        let message = "Error: 金额无效 💳"

        // When
        let result = ValidationResult.invalid(code: "UNICODE_ERROR", message: message)

        // Then
        XCTAssertEqual(result.errorMessage, message)
    }

    func test_invalid_withLongMessage() {
        // Given
        let longMessage = String(repeating: "A", count: 1000)

        // When
        let result = ValidationResult.invalid(code: "LONG_ERROR", message: longMessage)

        // Then
        XCTAssertEqual(result.errorMessage?.count, 1000)
    }
}
