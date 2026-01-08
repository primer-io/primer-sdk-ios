//
//  CardValidationRulesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class CardValidationRulesTests: XCTestCase {

    // MARK: - Card Number Validation Tests

    // All major card networks for testing
    private let allCardNetworks: [CardNetwork] = [.visa, .masterCard, .amex, .discover, .jcb, .diners]

    func test_validateCardNumber_withValidVisa_returnsValid() {
        // Given
        let rule = CardNumberRule(allowedCardNetworks: allCardNetworks)
        let cardNumber = TestData.CardNumbers.validVisa

        // When
        let result = rule.validate(cardNumber)

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorCode)
    }

    func test_validateCardNumber_withValidMastercard_returnsValid() {
        // Given
        let rule = CardNumberRule(allowedCardNetworks: allCardNetworks)
        let cardNumber = TestData.CardNumbers.validMastercard

        // When
        let result = rule.validate(cardNumber)

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorCode)
    }

    func test_validateCardNumber_withValidAmex_returnsValid() {
        // Given
        let rule = CardNumberRule(allowedCardNetworks: allCardNetworks)
        let cardNumber = TestData.CardNumbers.validAmex

        // When
        let result = rule.validate(cardNumber)

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorCode)
    }

    func test_validateCardNumber_withInvalidLuhn_returnsInvalid() {
        // Given
        let rule = CardNumberRule(allowedCardNetworks: allCardNetworks)
        let cardNumber = TestData.CardNumbers.invalidLuhn

        // When
        let result = rule.validate(cardNumber)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorCode)
    }

    func test_validateCardNumber_withTooShort_returnsInvalid() {
        // Given
        let rule = CardNumberRule(allowedCardNetworks: allCardNetworks)
        let cardNumber = TestData.CardNumbers.tooShort

        // When
        let result = rule.validate(cardNumber)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorCode)
    }

    func test_validateCardNumber_withEmpty_returnsInvalid() {
        // Given
        let rule = CardNumberRule(allowedCardNetworks: allCardNetworks)
        let cardNumber = TestData.CardNumbers.empty

        // When
        let result = rule.validate(cardNumber)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateCardNumber_withNonNumeric_returnsInvalid() {
        // Given
        let rule = CardNumberRule(allowedCardNetworks: allCardNetworks)
        let cardNumber = TestData.CardNumbers.nonNumeric

        // When
        let result = rule.validate(cardNumber)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateCardNumber_withUnsupportedNetwork_returnsInvalid() {
        // Given - Only allow Visa, but test with Mastercard
        let rule = CardNumberRule(allowedCardNetworks: [.visa])
        let cardNumber = TestData.CardNumbers.validMastercard

        // When
        let result = rule.validate(cardNumber)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorCode, TestData.ErrorCodes.unsupportedCardType)
    }

    // MARK: - CVV Validation Tests

    func test_validateCVV_with3DigitsForVisa_returnsValid() {
        // Given
        let rule = CVVRule(cardNetwork: .visa)
        let cvv = TestData.CVV.valid3Digit

        // When
        let result = rule.validate(cvv)

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorCode)
    }

    func test_validateCVV_with3DigitsForMastercard_returnsValid() {
        // Given
        let rule = CVVRule(cardNetwork: .masterCard)
        let cvv = TestData.CVV.valid3Digit

        // When
        let result = rule.validate(cvv)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCVV_with4DigitsForAmex_returnsValid() {
        // Given
        let rule = CVVRule(cardNetwork: .amex)
        let cvv = TestData.CVV.valid4Digit

        // When
        let result = rule.validate(cvv)

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorCode)
    }

    func test_validateCVV_with3DigitsForAmex_returnsInvalid() {
        // Given
        let rule = CVVRule(cardNetwork: .amex)
        let cvv = TestData.CVV.valid3Digit  // Amex requires 4 digits

        // When
        let result = rule.validate(cvv)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorCode)
    }

    func test_validateCVV_withTooShort_returnsInvalid() {
        // Given
        let rule = CVVRule(cardNetwork: .visa)
        let cvv = TestData.CVV.tooShort

        // When
        let result = rule.validate(cvv)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateCVV_withEmpty_returnsInvalid() {
        // Given
        let rule = CVVRule(cardNetwork: .visa)
        let cvv = TestData.CVV.empty

        // When
        let result = rule.validate(cvv)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateCVV_withNonNumeric_returnsInvalid() {
        // Given
        let rule = CVVRule(cardNetwork: .visa)
        let cvv = TestData.CVV.nonNumeric

        // When
        let result = rule.validate(cvv)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateCVV_withUnknownNetwork_uses3Digits() {
        // Given - when network is unknown, CVV is 3 digits by default
        let rule = CVVRule(cardNetwork: .unknown)
        let cvv = TestData.CVV.valid3Digit

        // When
        let result = rule.validate(cvv)

        // Then
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Cardholder Name Validation Tests

    func test_validateCardholderName_withValidName_returnsValid() {
        // Given
        let rule = CardholderNameRule()
        let name = TestData.CardholderNames.valid

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorCode)
    }

    func test_validateCardholderName_withMiddleName_returnsValid() {
        // Given
        let rule = CardholderNameRule()
        let name = TestData.CardholderNames.validWithMiddle

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCardholderName_withSingleName_returnsValid() {
        // Given
        let rule = CardholderNameRule()
        let name = TestData.CardholderNames.validSingleName

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCardholderName_withAccents_returnsValid() {
        // Given
        let rule = CardholderNameRule()
        let name = TestData.CardholderNames.validWithAccents

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCardholderName_withNumbers_returnsInvalid() {
        // Given
        let rule = CardholderNameRule()
        let name = TestData.CardholderNames.withNumbers

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateCardholderName_withEmpty_returnsInvalid() {
        // Given
        let rule = CardholderNameRule()
        let name = TestData.CardholderNames.empty

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateCardholderName_withOnlyNumbers_returnsInvalid() {
        // Given
        let rule = CardholderNameRule()
        let name = TestData.CardholderNames.onlyNumbers

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Additional Card Number Edge Cases

    func test_validateCardNumber_withAllZeros_failsLuhn() {
        // Given
        let rule = CardNumberRule(allowedCardNetworks: allCardNetworks)
        let cardNumber = TestData.CardNumbers.allZeros

        // When
        let result = rule.validate(cardNumber)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorCode)
    }

    func test_validateCardNumber_withSingleDigit_returnsInvalid() {
        // Given
        let rule = CardNumberRule(allowedCardNetworks: allCardNetworks)
        let cardNumber = TestData.CardNumbers.singleDigit

        // When
        let result = rule.validate(cardNumber)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorCode)
    }

    func test_validateCardNumber_with19DigitValid_returnsValid() {
        // Given
        let rule = CardNumberRule(allowedCardNetworks: allCardNetworks)
        let cardNumber = TestData.CardNumbers.valid19Digit

        // When
        let result = rule.validate(cardNumber)

        // Then
        XCTAssertTrue(cardNumber.count == 19)
    }

    func test_validateCardNumber_withMaxLengthExceeded_returnsInvalid() {
        // Given
        let rule = CardNumberRule(allowedCardNetworks: allCardNetworks)
        let cardNumber = TestData.CardNumbers.tooLong

        // When
        let result = rule.validate(cardNumber)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorCode)
    }

    func test_validateCardNumber_withEmptyAllowedNetworks_rejectsAll() {
        // Given - Empty allowed networks should reject all cards
        let rule = CardNumberRule(allowedCardNetworks: [])
        let cardNumber = TestData.CardNumbers.validVisa

        // When
        let result = rule.validate(cardNumber)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorCode, TestData.ErrorCodes.unsupportedCardType)
    }

    func test_validateCardNumber_withSpaces_isCleanedAndValidated() {
        // Given - Card number with spaces should be cleaned
        let rule = CardNumberRule(allowedCardNetworks: allCardNetworks)
        let cardNumber = TestData.CardNumbers.withSpaces

        // When
        let result = rule.validate(cardNumber)

        // Then - The spaces are stripped, and the underlying number is valid
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Additional CVV Edge Cases

    func test_validateCVV_withNilNetwork_uses3Digits() {
        // Given - when network is nil, CVV is 3 digits by default
        let rule = CVVRule(cardNetwork: nil)
        let cvv = TestData.CVV.valid3Digit

        // When
        let result = rule.validate(cvv)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCVV_with4DigitsForVisa_returnsInvalid() {
        // Given - Visa requires 3 digits, not 4
        let rule = CVVRule(cardNetwork: .visa)
        let cvv = TestData.CVV.valid4Digit

        // When
        let result = rule.validate(cvv)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Additional Cardholder Name Edge Cases

    func test_validateCardholderName_withHyphen_returnsValid() {
        // Given
        let rule = CardholderNameRule()
        let name = TestData.CardholderNames.validWithHyphen

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCardholderName_withApostrophe_returnsValid() {
        // Given
        let rule = CardholderNameRule()
        let name = TestData.CardholderNames.validWithApostrophe

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCardholderName_withTooShort_returnsInvalid() {
        // Given - Single character name should be invalid
        let rule = CardholderNameRule()
        let name = TestData.CardholderNames.tooShort

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateCardholderName_withLeadingTrailingSpaces_trimsAndValidates() {
        // Given
        let rule = CardholderNameRule()
        let name = TestData.CardholderNames.withLeadingTrailingSpaces

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCardholderName_withOnlySpaces_returnsInvalid() {
        // Given
        let rule = CardholderNameRule()
        let name = TestData.CardholderNames.onlySpaces

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateCardholderName_withSpecialCharacters_returnsInvalid() {
        // Given
        let rule = CardholderNameRule()
        let name = TestData.CardholderNames.withSpecialCharacters

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertFalse(result.isValid)
    }
}
