//
//  CardValidationRulesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class CardValidationRulesTests: XCTestCase {

    private let allCardNetworks: [CardNetwork] = [.visa, .masterCard, .amex, .discover, .jcb, .diners]

    // MARK: - Card Number Validation Tests

    func test_validateCardNumber_withValidCards_returnsValid() {
        let rule = CardNumberRule(allowedCardNetworks: allCardNetworks)
        let validCards: [String] = [
            TestData.CardNumbers.validVisa,
            TestData.CardNumbers.validMastercard,
            TestData.CardNumbers.validAmex,
            TestData.CardNumbers.withSpaces
        ]

        assertAllValid(rule: rule, values: validCards)
    }

    func test_validateCardNumber_withInvalidCards_returnsInvalid() {
        let rule = CardNumberRule(allowedCardNetworks: allCardNetworks)
        let invalidCards: [String] = [
            TestData.CardNumbers.invalidLuhn,
            TestData.CardNumbers.tooShort,
            TestData.CardNumbers.empty,
            TestData.CardNumbers.nonNumeric,
            TestData.CardNumbers.allZeros,
            TestData.CardNumbers.singleDigit,
            TestData.CardNumbers.tooLong
        ]

        assertAllInvalid(rule: rule, values: invalidCards)
    }

    func test_validateCardNumber_withUnsupportedNetwork_returnsUnsupportedError() {
        let rule = CardNumberRule(allowedCardNetworks: [.visa])
        let result = rule.validate(TestData.CardNumbers.validMastercard)

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorCode, TestData.ErrorCodes.unsupportedCardType)
    }

    func test_validateCardNumber_withEmptyAllowedNetworks_returnsUnsupportedError() {
        let rule = CardNumberRule(allowedCardNetworks: [])
        let result = rule.validate(TestData.CardNumbers.validVisa)

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorCode, TestData.ErrorCodes.unsupportedCardType)
    }

    func test_validateCardNumber_with19Digits_hasCorrectLength() {
        let cardNumber = TestData.CardNumbers.valid19Digit
        XCTAssertEqual(cardNumber.count, 19)
    }

    // MARK: - CVV Validation Tests

    func test_validateCVV_withValidCVVs_returnsValid() {
        let testCases: [(CardNetwork?, String)] = [
            (.visa, TestData.CVV.valid3Digit),
            (.masterCard, TestData.CVV.valid3Digit),
            (.amex, TestData.CVV.valid4Digit),
            (.unknown, TestData.CVV.valid3Digit),
            (nil, TestData.CVV.valid3Digit)
        ]

        for (network, cvv) in testCases {
            let rule = CVVRule(cardNetwork: network)
            let result = rule.validate(cvv)
            XCTAssertTrue(result.isValid, "Expected CVV '\(cvv)' to be valid for network \(String(describing: network))")
        }
    }

    func test_validateCVV_withInvalidCVVs_returnsInvalid() {
        let rule = CVVRule(cardNetwork: .visa)
        let invalidCVVs: [String] = [
            TestData.CVV.tooShort,
            TestData.CVV.empty,
            TestData.CVV.nonNumeric,
            TestData.CVV.valid4Digit  // Visa requires 3 digits
        ]

        assertAllInvalid(rule: rule, values: invalidCVVs)
    }

    func test_validateCVV_amexWith3Digits_returnsInvalid() {
        let rule = CVVRule(cardNetwork: .amex)
        let result = rule.validate(TestData.CVV.valid3Digit)

        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorCode)
    }

    // MARK: - Cardholder Name Validation Tests

    func test_validateCardholderName_withValidNames_returnsValid() {
        let rule = CardholderNameRule()
        let validNames: [String] = [
            TestData.CardholderNames.valid,
            TestData.CardholderNames.validWithMiddle,
            TestData.CardholderNames.validSingleName,
            TestData.CardholderNames.validWithAccents,
            TestData.CardholderNames.validWithHyphen,
            TestData.CardholderNames.validWithApostrophe,
            TestData.CardholderNames.withLeadingTrailingSpaces
        ]

        assertAllValid(rule: rule, values: validNames)
    }

    func test_validateCardholderName_withInvalidNames_returnsInvalid() {
        let rule = CardholderNameRule()
        let invalidNames: [String] = [
            TestData.CardholderNames.withNumbers,
            TestData.CardholderNames.empty,
            TestData.CardholderNames.onlyNumbers,
            TestData.CardholderNames.tooShort,
            TestData.CardholderNames.onlySpaces,
            TestData.CardholderNames.withSpecialCharacters
        ]

        assertAllInvalid(rule: rule, values: invalidNames)
    }

    // MARK: - Helpers

    private func assertAllValid<R: ValidationRule>(rule: R, values: [String], file: StaticString = #file, line: UInt = #line) where R.Input == String {
        for value in values {
            let result = rule.validate(value)
            XCTAssertTrue(result.isValid, "Expected '\(value)' to be valid", file: file, line: line)
        }
    }

    private func assertAllInvalid<R: ValidationRule>(rule: R, values: [String], file: StaticString = #file, line: UInt = #line) where R.Input == String {
        for value in values {
            let result = rule.validate(value)
            XCTAssertFalse(result.isValid, "Expected '\(value)' to be invalid", file: file, line: line)
        }
    }
}
