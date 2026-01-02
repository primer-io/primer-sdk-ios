//
//  PrimerInputElementTypeExtendedTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Extended tests for PrimerInputElementType covering computed properties, formatting, and additional validation cases.
final class PrimerInputElementTypeExtendedTests: XCTestCase {

    // MARK: - stringValue Tests

    func test_stringValue_cardNumber_returnsCorrectString() {
        XCTAssertEqual(PrimerInputElementType.cardNumber.stringValue, "CARD_NUMBER")
    }

    func test_stringValue_expiryDate_returnsCorrectString() {
        XCTAssertEqual(PrimerInputElementType.expiryDate.stringValue, "EXPIRY_DATE")
    }

    func test_stringValue_cvv_returnsCorrectString() {
        XCTAssertEqual(PrimerInputElementType.cvv.stringValue, "CVV")
    }

    func test_stringValue_cardholderName_returnsCorrectString() {
        XCTAssertEqual(PrimerInputElementType.cardholderName.stringValue, "CARDHOLDER_NAME")
    }

    func test_stringValue_allCases_returnExpectedStrings() {
        let expectedValues: [PrimerInputElementType: String] = [
            .otp: "OTP",
            .postalCode: "POSTAL_CODE",
            .phoneNumber: "PHONE_NUMBER",
            .retailer: "RETAILER",
            .countryCode: "COUNTRY_CODE",
            .firstName: "FIRST_NAME",
            .lastName: "LAST_NAME",
            .addressLine1: "ADDRESS_LINE_1",
            .addressLine2: "ADDRESS_LINE_2",
            .city: "CITY",
            .state: "STATE",
            .email: "EMAIL",
            .all: "ALL",
            .unknown: "UNKNOWN"
        ]

        for (type, expected) in expectedValues {
            XCTAssertEqual(type.stringValue, expected, "\(type) should return \(expected)")
        }
    }

    // MARK: - delimiter Tests

    func test_delimiter_cardNumber_returnsSpace() {
        XCTAssertEqual(PrimerInputElementType.cardNumber.delimiter, " ")
    }

    func test_delimiter_expiryDate_returnsSlash() {
        XCTAssertEqual(PrimerInputElementType.expiryDate.delimiter, "/")
    }

    func test_delimiter_otherFields_returnsNil() {
        let fieldsWithNoDelimiter: [PrimerInputElementType] = [
            .cvv, .cardholderName, .otp, .postalCode, .phoneNumber,
            .retailer, .countryCode, .firstName, .lastName,
            .addressLine1, .addressLine2, .city, .state, .email, .all, .unknown
        ]

        for field in fieldsWithNoDelimiter {
            XCTAssertNil(field.delimiter, "\(field) should have no delimiter")
        }
    }

    // MARK: - maxAllowedLength Tests

    func test_maxAllowedLength_expiryDate_returnsFour() {
        XCTAssertEqual(PrimerInputElementType.expiryDate.maxAllowedLength, 4)
    }

    func test_maxAllowedLength_postalCode_returnsTen() {
        XCTAssertEqual(PrimerInputElementType.postalCode.maxAllowedLength, 10)
    }

    func test_maxAllowedLength_cardNumber_returnsNil() {
        XCTAssertNil(PrimerInputElementType.cardNumber.maxAllowedLength)
    }

    func test_maxAllowedLength_cvv_returnsNil() {
        XCTAssertNil(PrimerInputElementType.cvv.maxAllowedLength)
    }

    func test_maxAllowedLength_mostFields_returnNil() {
        let fieldsWithNoMaxLength: [PrimerInputElementType] = [
            .cardholderName, .otp, .phoneNumber, .retailer,
            .countryCode, .firstName, .lastName, .addressLine1,
            .addressLine2, .city, .state, .email, .all, .unknown
        ]

        for field in fieldsWithNoMaxLength {
            XCTAssertNil(field.maxAllowedLength, "\(field) should have no max length")
        }
    }

    // MARK: - allowedCharacterSet Tests

    func test_allowedCharacterSet_numericFields_returnNumericSet() {
        let numericFields: [PrimerInputElementType] = [
            .cardNumber, .expiryDate, .cvv, .otp, .phoneNumber
        ]
        let expectedSet = CharacterSet(charactersIn: "0123456789")

        for field in numericFields {
            XCTAssertEqual(field.allowedCharacterSet, expectedSet, "\(field) should allow only digits")
        }
    }

    func test_allowedCharacterSet_nameFields_returnLettersAndWhitespace() {
        let nameFields: [PrimerInputElementType] = [
            .cardholderName, .firstName, .lastName
        ]
        let expectedSet = CharacterSet.letters.union(.whitespaces)

        for field in nameFields {
            XCTAssertEqual(field.allowedCharacterSet, expectedSet, "\(field) should allow letters and whitespace")
        }
    }

    func test_allowedCharacterSet_otherFields_returnNil() {
        let fieldsWithNoRestriction: [PrimerInputElementType] = [
            .postalCode, .retailer, .countryCode, .addressLine1,
            .addressLine2, .city, .state, .email, .all, .unknown
        ]

        for field in fieldsWithNoRestriction {
            XCTAssertNil(field.allowedCharacterSet, "\(field) should have no character restriction")
        }
    }

    // MARK: - keyboardType Tests

    func test_keyboardType_numericFields_returnNumberPad() {
        let numericFields: [PrimerInputElementType] = [
            .cardNumber, .expiryDate, .cvv, .otp, .phoneNumber, .postalCode
        ]

        for field in numericFields {
            XCTAssertEqual(field.keyboardType, .numberPad, "\(field) should use number pad")
        }
    }

    func test_keyboardType_nameFields_returnAlphabet() {
        let alphaFields: [PrimerInputElementType] = [
            .cardholderName, .firstName, .lastName, .city, .state
        ]

        for field in alphaFields {
            XCTAssertEqual(field.keyboardType, .alphabet, "\(field) should use alphabet keyboard")
        }
    }

    func test_keyboardType_email_returnEmailAddress() {
        XCTAssertEqual(PrimerInputElementType.email.keyboardType, .emailAddress)
    }

    func test_keyboardType_defaultFields_returnDefault() {
        let defaultFields: [PrimerInputElementType] = [
            .addressLine1, .addressLine2, .countryCode, .retailer, .unknown, .all
        ]

        for field in defaultFields {
            XCTAssertEqual(field.keyboardType, .default, "\(field) should use default keyboard")
        }
    }

    // MARK: - isCardField Tests

    func test_isCardField_cardFields_returnTrue() {
        let cardFields: [PrimerInputElementType] = [
            .cardNumber, .expiryDate, .cvv, .cardholderName
        ]

        for field in cardFields {
            XCTAssertTrue(field.isCardField, "\(field) should be a card field")
        }
    }

    func test_isCardField_nonCardFields_returnFalse() {
        let nonCardFields: [PrimerInputElementType] = [
            .otp, .postalCode, .phoneNumber, .retailer, .countryCode,
            .firstName, .lastName, .addressLine1, .addressLine2,
            .city, .state, .email, .all, .unknown
        ]

        for field in nonCardFields {
            XCTAssertFalse(field.isCardField, "\(field) should not be a card field")
        }
    }

    // MARK: - isBillingField Tests

    func test_isBillingField_billingFields_returnTrue() {
        let billingFields: [PrimerInputElementType] = [
            .firstName, .lastName, .addressLine1, .addressLine2,
            .city, .state, .postalCode, .countryCode, .phoneNumber, .email
        ]

        for field in billingFields {
            XCTAssertTrue(field.isBillingField, "\(field) should be a billing field")
        }
    }

    func test_isBillingField_nonBillingFields_returnFalse() {
        let nonBillingFields: [PrimerInputElementType] = [
            .cardNumber, .expiryDate, .cvv, .cardholderName,
            .otp, .retailer, .all, .unknown
        ]

        for field in nonBillingFields {
            XCTAssertFalse(field.isBillingField, "\(field) should not be a billing field")
        }
    }

    // MARK: - isRequired Tests

    func test_isRequired_requiredFields_returnTrue() {
        let requiredFields: [PrimerInputElementType] = [
            .cardNumber, .expiryDate, .cvv, .cardholderName, .postalCode, .countryCode
        ]

        for field in requiredFields {
            XCTAssertTrue(field.isRequired, "\(field) should be required")
        }
    }

    func test_isRequired_optionalFields_returnFalse() {
        let optionalFields: [PrimerInputElementType] = [
            .otp, .phoneNumber, .retailer, .firstName, .lastName,
            .addressLine1, .addressLine2, .city, .state, .email, .all, .unknown
        ]

        for field in optionalFields {
            XCTAssertFalse(field.isRequired, "\(field) should not be required")
        }
    }

    // MARK: - displayOrder Tests

    func test_displayOrder_cardFields_returnCorrectOrder() {
        XCTAssertEqual(PrimerInputElementType.cardNumber.displayOrder, 1)
        XCTAssertEqual(PrimerInputElementType.expiryDate.displayOrder, 2)
        XCTAssertEqual(PrimerInputElementType.cvv.displayOrder, 3)
        XCTAssertEqual(PrimerInputElementType.cardholderName.displayOrder, 4)
    }

    func test_displayOrder_billingFields_returnCorrectOrder() {
        XCTAssertEqual(PrimerInputElementType.countryCode.displayOrder, 10)
        XCTAssertEqual(PrimerInputElementType.addressLine1.displayOrder, 11)
        XCTAssertEqual(PrimerInputElementType.postalCode.displayOrder, 12)
        XCTAssertEqual(PrimerInputElementType.state.displayOrder, 13)
        XCTAssertEqual(PrimerInputElementType.city.displayOrder, 14)
        XCTAssertEqual(PrimerInputElementType.addressLine2.displayOrder, 15)
        XCTAssertEqual(PrimerInputElementType.firstName.displayOrder, 16)
        XCTAssertEqual(PrimerInputElementType.lastName.displayOrder, 17)
        XCTAssertEqual(PrimerInputElementType.email.displayOrder, 18)
        XCTAssertEqual(PrimerInputElementType.phoneNumber.displayOrder, 19)
    }

    func test_displayOrder_otherFields_returnCorrectOrder() {
        XCTAssertEqual(PrimerInputElementType.otp.displayOrder, 20)
        XCTAssertEqual(PrimerInputElementType.retailer.displayOrder, 21)
        XCTAssertEqual(PrimerInputElementType.unknown.displayOrder, 999)
        XCTAssertEqual(PrimerInputElementType.all.displayOrder, 999)
    }

    // MARK: - displayName Tests

    func test_displayName_allCases_returnHumanReadableStrings() {
        let expectedNames: [PrimerInputElementType: String] = [
            .cardNumber: "Card Number",
            .expiryDate: "Expiry Date",
            .cvv: "CVV",
            .cardholderName: "Cardholder Name",
            .firstName: "First Name",
            .lastName: "Last Name",
            .addressLine1: "Address Line 1",
            .addressLine2: "Address Line 2",
            .city: "City",
            .state: "State",
            .postalCode: "Postal Code",
            .countryCode: "Country",
            .phoneNumber: "Phone Number",
            .email: "Email",
            .otp: "OTP Code",
            .retailer: "Retail Outlet",
            .unknown: "Unknown",
            .all: "All Fields"
        ]

        for (type, expected) in expectedNames {
            XCTAssertEqual(type.displayName, expected, "\(type) should display as '\(expected)'")
        }
    }

    // MARK: - format() Tests

    func test_format_cardNumber_addsSpaces() {
        let sut = PrimerInputElementType.cardNumber
        let result = sut.format(value: "4242424242424242") as? String

        XCTAssertEqual(result, "4242 4242 4242 4242")
    }

    func test_format_cardNumber_handlesPartialInput() {
        let sut = PrimerInputElementType.cardNumber

        XCTAssertEqual(sut.format(value: "4242") as? String, "4242")
        XCTAssertEqual(sut.format(value: "42424242") as? String, "4242 4242")
    }

    func test_format_expiryDate_addsSlash() {
        let sut = PrimerInputElementType.expiryDate
        let result = sut.format(value: "1225") as? String

        XCTAssertEqual(result, "12/25")
    }

    func test_format_expiryDate_handlesPartialInput() {
        let sut = PrimerInputElementType.expiryDate

        XCTAssertEqual(sut.format(value: "12") as? String, "12")
        XCTAssertEqual(sut.format(value: "1") as? String, "1")
    }

    func test_format_otherFields_returnsValueUnchanged() {
        let fields: [PrimerInputElementType] = [
            .cvv, .cardholderName, .otp, .postalCode, .phoneNumber,
            .firstName, .lastName, .email
        ]

        for field in fields {
            let result = field.format(value: "test123") as? String
            XCTAssertEqual(result, "test123", "\(field) should return value unchanged")
        }
    }

    func test_format_nonStringValue_returnsValueUnchanged() {
        let sut = PrimerInputElementType.cardNumber
        let result = sut.format(value: 1234) as? Int

        XCTAssertEqual(result, 1234)
    }

    // MARK: - clearFormatting() Tests

    func test_clearFormatting_cardNumber_removesSpaces() {
        let sut = PrimerInputElementType.cardNumber
        let result = sut.clearFormatting(value: "4242 4242 4242 4242") as? String

        XCTAssertEqual(result, "4242424242424242")
    }

    func test_clearFormatting_expiryDate_removesSlash() {
        let sut = PrimerInputElementType.expiryDate
        let result = sut.clearFormatting(value: "12/25") as? String

        XCTAssertEqual(result, "1225")
    }

    func test_clearFormatting_otherFields_returnsValueUnchanged() {
        let fields: [PrimerInputElementType] = [
            .cvv, .cardholderName, .otp, .postalCode, .phoneNumber,
            .firstName, .lastName, .email
        ]

        for field in fields {
            let result = field.clearFormatting(value: "test123") as? String
            XCTAssertEqual(result, "test123", "\(field) should return value unchanged")
        }
    }

    func test_clearFormatting_nonStringValue_returnsNil() {
        let sut = PrimerInputElementType.cardNumber
        let result = sut.clearFormatting(value: 1234)

        XCTAssertNil(result)
    }

    // MARK: - detectType() Tests

    func test_detectType_cardNumber_returnsCardNetwork() {
        let sut = PrimerInputElementType.cardNumber
        let result = sut.detectType(for: "4242424242424242")

        XCTAssertNotNil(result)
        XCTAssertTrue(result is CardNetwork)
    }

    func test_detectType_cardNumber_detectsVisa() {
        let sut = PrimerInputElementType.cardNumber
        let result = sut.detectType(for: "4111111111111111") as? CardNetwork

        XCTAssertEqual(result, .visa)
    }

    func test_detectType_cardNumber_nonStringReturnsNil() {
        let sut = PrimerInputElementType.cardNumber
        let result = sut.detectType(for: 4242424242424242)

        XCTAssertNil(result)
    }

    func test_detectType_otherFields_returnsValueUnchanged() {
        let fields: [PrimerInputElementType] = [
            .expiryDate, .cvv, .cardholderName, .otp, .postalCode
        ]

        for field in fields {
            let result = field.detectType(for: "test") as? String
            XCTAssertEqual(result, "test", "\(field) should return value unchanged")
        }
    }

    // MARK: - Additional validate() Tests (Missing Cases)

    func test_validate_firstName_validInput() {
        let sut = PrimerInputElementType.firstName

        XCTAssertTrue(sut.validate(value: "John", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: "Mary Jane", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "John123", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "", detectedValueType: nil))
    }

    func test_validate_lastName_validInput() {
        let sut = PrimerInputElementType.lastName

        XCTAssertTrue(sut.validate(value: "Doe", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: "Van Der Berg", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "Doe3rd", detectedValueType: nil))
    }

    func test_validate_addressLine1_nonEmptyValid() {
        let sut = PrimerInputElementType.addressLine1

        XCTAssertTrue(sut.validate(value: "123 Main Street", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: "Apt 4B", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "", detectedValueType: nil))
    }

    func test_validate_addressLine2_nonEmptyValid() {
        let sut = PrimerInputElementType.addressLine2

        XCTAssertTrue(sut.validate(value: "Suite 100", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "", detectedValueType: nil))
    }

    func test_validate_city_nonEmptyValid() {
        let sut = PrimerInputElementType.city

        XCTAssertTrue(sut.validate(value: "New York", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: "San Francisco", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "", detectedValueType: nil))
    }

    func test_validate_state_nonEmptyValid() {
        let sut = PrimerInputElementType.state

        XCTAssertTrue(sut.validate(value: "CA", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: "California", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "", detectedValueType: nil))
    }

    func test_validate_countryCode_nonEmptyValid() {
        let sut = PrimerInputElementType.countryCode

        XCTAssertTrue(sut.validate(value: "US", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: "GB", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "", detectedValueType: nil))
    }

    func test_validate_email_requiresAtAndDot() {
        let sut = PrimerInputElementType.email

        XCTAssertTrue(sut.validate(value: "test@example.com", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: "user.name@domain.co.uk", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "invalid-email", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "missing@dot", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "missing.at.symbol", detectedValueType: nil))
    }

    func test_validate_all_alwaysReturnsTrue() {
        let sut = PrimerInputElementType.all

        XCTAssertTrue(sut.validate(value: "", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: "anything", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: 123, detectedValueType: nil))
    }

    func test_validate_retailer_alwaysReturnsTrue() {
        let sut = PrimerInputElementType.retailer

        XCTAssertTrue(sut.validate(value: "", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: "any value", detectedValueType: nil))
    }

    func test_validate_unknown_alwaysReturnsFalse() {
        let sut = PrimerInputElementType.unknown

        XCTAssertFalse(sut.validate(value: "", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "anything", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "valid looking input", detectedValueType: nil))
    }
}
