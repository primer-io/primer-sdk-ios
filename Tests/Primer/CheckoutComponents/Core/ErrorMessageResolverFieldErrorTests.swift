//
//  ErrorMessageResolverFieldErrorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class ErrorMessageResolverFieldErrorTests: XCTestCase {

    // MARK: - Test Data

    /// Expected error message keys for required field errors
    private let requiredErrorMessageKeys: [ValidationError.InputElementType: String] = [
        .firstName: TestData.ErrorMessageKeys.firstNameRequired,
        .lastName: TestData.ErrorMessageKeys.lastNameRequired,
        .email: TestData.ErrorMessageKeys.emailRequired,
        .countryCode: TestData.ErrorMessageKeys.countryRequired,
        .addressLine1: TestData.ErrorMessageKeys.addressLine1Required,
        .addressLine2: TestData.ErrorMessageKeys.addressLine2Required,
        .city: TestData.ErrorMessageKeys.cityRequired,
        .state: TestData.ErrorMessageKeys.stateRequired,
        .postalCode: TestData.ErrorMessageKeys.postalCodeRequired,
        .phoneNumber: TestData.ErrorMessageKeys.phoneNumberRequired,
        .retailOutlet: TestData.ErrorMessageKeys.retailOutletRequired
    ]

    /// Expected error message keys for invalid field errors
    private let invalidErrorMessageKeys: [ValidationError.InputElementType: String] = [
        .cardNumber: TestData.ErrorMessageKeys.cardNumberInvalid,
        .cvv: TestData.ErrorMessageKeys.cvvInvalid,
        .expiryDate: TestData.ErrorMessageKeys.expiryDateInvalid,
        .cardholderName: TestData.ErrorMessageKeys.cardholderNameInvalid,
        .firstName: TestData.ErrorMessageKeys.firstNameInvalid,
        .lastName: TestData.ErrorMessageKeys.lastNameInvalid,
        .email: TestData.ErrorMessageKeys.emailInvalid,
        .countryCode: TestData.ErrorMessageKeys.countryInvalid,
        .addressLine1: TestData.ErrorMessageKeys.addressLine1Invalid,
        .addressLine2: TestData.ErrorMessageKeys.addressLine2Invalid,
        .city: TestData.ErrorMessageKeys.cityInvalid,
        .state: TestData.ErrorMessageKeys.stateInvalid,
        .postalCode: TestData.ErrorMessageKeys.postalCodeInvalid,
        .phoneNumber: TestData.ErrorMessageKeys.phoneNumberInvalid,
        .retailOutlet: TestData.ErrorMessageKeys.retailOutletInvalid
    ]

    /// Types that support required field errors
    private var typesWithRequiredErrors: [ValidationError.InputElementType] {
        Array(requiredErrorMessageKeys.keys)
    }

    /// Types that support invalid field errors
    private var typesWithInvalidErrors: [ValidationError.InputElementType] {
        Array(invalidErrorMessageKeys.keys)
    }

    // MARK: - Helper Methods

    private func assertRequiredFieldError(
        for type: ValidationError.InputElementType,
        expectedMessageKey: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let error = ErrorMessageResolver.createRequiredFieldError(for: type)

        XCTAssertEqual(error.inputElementType, type, file: file, line: line)
        XCTAssertEqual(error.errorMessageKey, expectedMessageKey,
                       "Expected message key '\(expectedMessageKey)' for \(type), got '\(error.errorMessageKey ?? "nil")'",
                       file: file, line: line)
        XCTAssertEqual(error.errorId, "\(type.rawValue.lowercased())_required", file: file, line: line)
        XCTAssertEqual(error.code, "invalid-\(type.rawValue.lowercased())", file: file, line: line)
        XCTAssertEqual(error.message, TestData.ErrorMessages.fieldRequired, file: file, line: line)
    }

    private func assertInvalidFieldError(
        for type: ValidationError.InputElementType,
        expectedMessageKey: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let error = ErrorMessageResolver.createInvalidFieldError(for: type)

        XCTAssertEqual(error.inputElementType, type, file: file, line: line)
        XCTAssertEqual(error.errorMessageKey, expectedMessageKey,
                       "Expected message key '\(expectedMessageKey)' for \(type), got '\(error.errorMessageKey ?? "nil")'",
                       file: file, line: line)
        XCTAssertEqual(error.errorId, "\(type.rawValue.lowercased())_invalid", file: file, line: line)
        XCTAssertEqual(error.code, "invalid-\(type.rawValue.lowercased())", file: file, line: line)
        XCTAssertEqual(error.message, TestData.ErrorMessages.fieldInvalid, file: file, line: line)
    }

    // MARK: - createRequiredFieldError Tests

    func test_createRequiredFieldError_forAllSupportedTypes_createsCorrectErrors() {
        for (type, expectedMessageKey) in requiredErrorMessageKeys {
            assertRequiredFieldError(for: type, expectedMessageKey: expectedMessageKey)
        }
    }

    func test_createRequiredFieldError_forUnknown_usesGenericKey() {
        let error = ErrorMessageResolver.createRequiredFieldError(for: .unknown)

        XCTAssertEqual(error.inputElementType, .unknown)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.genericRequired)
    }

    // MARK: - createInvalidFieldError Tests

    func test_createInvalidFieldError_forAllSupportedTypes_createsCorrectErrors() {
        for (type, expectedMessageKey) in invalidErrorMessageKeys {
            assertInvalidFieldError(for: type, expectedMessageKey: expectedMessageKey)
        }
    }

    func test_createInvalidFieldError_forUnknown_usesGenericKey() {
        let error = ErrorMessageResolver.createInvalidFieldError(for: .unknown)

        XCTAssertEqual(error.inputElementType, .unknown)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.genericInvalid)
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
        // Test all cases except those that don't support required errors (card-related types and otpCode)
        let unsupportedTypes: Set<ValidationError.InputElementType> = [
            .cardNumber, .cvv, .expiryDate, .cardholderName, .otpCode, .unknown
        ]

        for type in ValidationError.InputElementType.allCases where !unsupportedTypes.contains(type) {
            let error = ErrorMessageResolver.createRequiredFieldError(for: type)
            let message = ErrorMessageResolver.resolveErrorMessage(for: error)

            XCTAssertNotEqual(message, CheckoutComponentsStrings.unexpectedError,
                              "Type \(type) should have a valid required error message")
        }
    }

    func test_allInputElementTypes_haveInvalidErrorKeys() {
        // Test all cases except those that don't support invalid errors (otpCode and unknown)
        let unsupportedTypes: Set<ValidationError.InputElementType> = [.otpCode, .unknown]

        for type in ValidationError.InputElementType.allCases where !unsupportedTypes.contains(type) {
            let error = ErrorMessageResolver.createInvalidFieldError(for: type)
            let message = ErrorMessageResolver.resolveErrorMessage(for: error)

            XCTAssertNotEqual(message, CheckoutComponentsStrings.unexpectedError,
                              "Type \(type) should have a valid invalid error message")
        }
    }

    // MARK: - Exhaustive Coverage Test

    func test_allInputElementTypes_areHandled() {
        // Ensure we've considered all InputElementType cases
        // This test will fail if a new case is added to the enum without updating the tests
        let allTypes = Set(ValidationError.InputElementType.allCases)
        let handledInRequired = Set(typesWithRequiredErrors + [.unknown, .cardNumber, .cvv, .expiryDate, .cardholderName, .otpCode])
        let handledInInvalid = Set(typesWithInvalidErrors + [.unknown, .otpCode])

        XCTAssertEqual(allTypes, handledInRequired,
                       "All InputElementTypes should be handled in required error tests")
        XCTAssertEqual(allTypes, handledInInvalid,
                       "All InputElementTypes should be handled in invalid error tests")
    }
}
