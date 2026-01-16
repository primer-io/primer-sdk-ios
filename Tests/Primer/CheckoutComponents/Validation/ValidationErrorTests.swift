//
//  ValidationErrorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

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
