//
//  ErrorMessageResolverFieldErrorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class ErrorMessageResolverFieldErrorTests: XCTestCase {

    // MARK: - createRequiredFieldError Tests

    func test_createRequiredFieldError_forFirstName_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .firstName)

        // Then
        XCTAssertEqual(error.inputElementType, .firstName)
        XCTAssertEqual(error.errorId, TestData.ErrorIds.firstNameRequired)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.firstNameRequired)
        XCTAssertEqual(error.code, TestData.ErrorCodes.invalidFirstName)
        XCTAssertEqual(error.message, TestData.ErrorMessages.fieldRequired)
    }

    func test_createRequiredFieldError_forLastName_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .lastName)

        // Then
        XCTAssertEqual(error.inputElementType, .lastName)
        XCTAssertEqual(error.errorId, TestData.ErrorIds.lastNameRequired)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.lastNameRequired)
    }

    func test_createRequiredFieldError_forEmail_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .email)

        // Then
        XCTAssertEqual(error.inputElementType, .email)
        XCTAssertEqual(error.errorId, TestData.ErrorIds.emailRequired)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.emailRequired)
    }

    func test_createRequiredFieldError_forCountryCode_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .countryCode)

        // Then
        XCTAssertEqual(error.inputElementType, .countryCode)
        XCTAssertEqual(error.errorId, TestData.ErrorIds.countryCodeRequired)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.countryRequired)
    }

    func test_createRequiredFieldError_forAddressLine1_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .addressLine1)

        // Then
        XCTAssertEqual(error.inputElementType, .addressLine1)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.addressLine1Required)
    }

    func test_createRequiredFieldError_forAddressLine2_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .addressLine2)

        // Then
        XCTAssertEqual(error.inputElementType, .addressLine2)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.addressLine2Required)
    }

    func test_createRequiredFieldError_forCity_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .city)

        // Then
        XCTAssertEqual(error.inputElementType, .city)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.cityRequired)
    }

    func test_createRequiredFieldError_forState_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .state)

        // Then
        XCTAssertEqual(error.inputElementType, .state)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.stateRequired)
    }

    func test_createRequiredFieldError_forPostalCode_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .postalCode)

        // Then
        XCTAssertEqual(error.inputElementType, .postalCode)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.postalCodeRequired)
    }

    func test_createRequiredFieldError_forPhoneNumber_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .phoneNumber)

        // Then
        XCTAssertEqual(error.inputElementType, .phoneNumber)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.phoneNumberRequired)
    }

    func test_createRequiredFieldError_forRetailOutlet_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .retailOutlet)

        // Then
        XCTAssertEqual(error.inputElementType, .retailOutlet)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.retailOutletRequired)
    }

    func test_createRequiredFieldError_forUnknown_usesGenericKey() {
        // When
        let error = ErrorMessageResolver.createRequiredFieldError(for: .unknown)

        // Then
        XCTAssertEqual(error.inputElementType, .unknown)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.genericRequired)
    }

    // MARK: - createInvalidFieldError Tests

    func test_createInvalidFieldError_forCardNumber_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .cardNumber)

        // Then
        XCTAssertEqual(error.inputElementType, .cardNumber)
        XCTAssertEqual(error.errorId, TestData.ErrorIds.cardNumberInvalid)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.cardNumberInvalid)
        XCTAssertEqual(error.code, TestData.ErrorCodes.invalidCardNumber)
        XCTAssertEqual(error.message, TestData.ErrorMessages.fieldInvalid)
    }

    func test_createInvalidFieldError_forCVV_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .cvv)

        // Then
        XCTAssertEqual(error.inputElementType, .cvv)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.cvvInvalid)
    }

    func test_createInvalidFieldError_forExpiryDate_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .expiryDate)

        // Then
        XCTAssertEqual(error.inputElementType, .expiryDate)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.expiryDateInvalid)
    }

    func test_createInvalidFieldError_forCardholderName_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .cardholderName)

        // Then
        XCTAssertEqual(error.inputElementType, .cardholderName)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.cardholderNameInvalid)
    }

    func test_createInvalidFieldError_forFirstName_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .firstName)

        // Then
        XCTAssertEqual(error.inputElementType, .firstName)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.firstNameInvalid)
    }

    func test_createInvalidFieldError_forLastName_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .lastName)

        // Then
        XCTAssertEqual(error.inputElementType, .lastName)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.lastNameInvalid)
    }

    func test_createInvalidFieldError_forEmail_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .email)

        // Then
        XCTAssertEqual(error.inputElementType, .email)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.emailInvalid)
    }

    func test_createInvalidFieldError_forCountryCode_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .countryCode)

        // Then
        XCTAssertEqual(error.inputElementType, .countryCode)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.countryInvalid)
    }

    func test_createInvalidFieldError_forAddressLine1_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .addressLine1)

        // Then
        XCTAssertEqual(error.inputElementType, .addressLine1)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.addressLine1Invalid)
    }

    func test_createInvalidFieldError_forAddressLine2_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .addressLine2)

        // Then
        XCTAssertEqual(error.inputElementType, .addressLine2)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.addressLine2Invalid)
    }

    func test_createInvalidFieldError_forCity_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .city)

        // Then
        XCTAssertEqual(error.inputElementType, .city)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.cityInvalid)
    }

    func test_createInvalidFieldError_forState_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .state)

        // Then
        XCTAssertEqual(error.inputElementType, .state)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.stateInvalid)
    }

    func test_createInvalidFieldError_forPostalCode_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .postalCode)

        // Then
        XCTAssertEqual(error.inputElementType, .postalCode)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.postalCodeInvalid)
    }

    func test_createInvalidFieldError_forPhoneNumber_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .phoneNumber)

        // Then
        XCTAssertEqual(error.inputElementType, .phoneNumber)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.phoneNumberInvalid)
    }

    func test_createInvalidFieldError_forRetailOutlet_createsCorrectError() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .retailOutlet)

        // Then
        XCTAssertEqual(error.inputElementType, .retailOutlet)
        XCTAssertEqual(error.errorMessageKey, TestData.ErrorMessageKeys.retailOutletInvalid)
    }

    func test_createInvalidFieldError_forUnknown_usesGenericKey() {
        // When
        let error = ErrorMessageResolver.createInvalidFieldError(for: .unknown)

        // Then
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
        let typesToTest: [ValidationError.InputElementType] = [
            .firstName, .lastName, .email, .countryCode,
            .addressLine1, .addressLine2, .city, .state,
            .postalCode, .phoneNumber, .retailOutlet
        ]

        for type in typesToTest {
            let error = ErrorMessageResolver.createRequiredFieldError(for: type)
            let message = ErrorMessageResolver.resolveErrorMessage(for: error)

            XCTAssertNotEqual(message, CheckoutComponentsStrings.unexpectedError,
                              "Type \(type) should have a valid required error message")
        }
    }

    func test_allInputElementTypes_haveInvalidErrorKeys() {
        let typesToTest: [ValidationError.InputElementType] = [
            .cardNumber, .cvv, .expiryDate, .cardholderName,
            .firstName, .lastName, .email, .countryCode,
            .addressLine1, .addressLine2, .city, .state,
            .postalCode, .phoneNumber, .retailOutlet
        ]

        for type in typesToTest {
            let error = ErrorMessageResolver.createInvalidFieldError(for: type)
            let message = ErrorMessageResolver.resolveErrorMessage(for: error)

            XCTAssertNotEqual(message, CheckoutComponentsStrings.unexpectedError,
                              "Type \(type) should have a valid invalid error message")
        }
    }
}
