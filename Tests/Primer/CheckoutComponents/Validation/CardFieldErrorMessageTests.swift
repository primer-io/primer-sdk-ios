//
//  CardFieldErrorMessageTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class CardFieldErrorMessageTests: XCTestCase {

    private let cardNumberRule = CardNumberRule(allowedCardNetworks: [.visa, .masterCard, .amex])

    func test_cardNumber_empty_isRequired() {
        assertMessage(cardNumberRule.validate(TestData.CardNumbers.empty), CheckoutComponentsStrings.cardNumberRequired)
    }

    func test_cardNumber_shorterThanAnyCard_isIncomplete() {
        assertMessage(cardNumberRule.validate(TestData.CardNumbers.tooShort), CheckoutComponentsStrings.cardNumberIncomplete)
    }

    func test_cardNumber_shorterThanItsNetwork_isIncomplete() {
        assertMessage(
            cardNumberRule.validate(TestData.CardNumbers.incompleteVisa),
            CheckoutComponentsStrings.cardNumberIncomplete
        )
    }

    func test_cardNumber_longerThanItsNetwork_isInvalid() {
        assertMessage(cardNumberRule.validate(TestData.CardNumbers.tooLongAmex), CheckoutComponentsStrings.enterValidCardNumber)
    }

    func test_cardNumber_failingTheCheck_isInvalid() {
        assertMessage(cardNumberRule.validate(TestData.CardNumbers.invalidLuhn), CheckoutComponentsStrings.enterValidCardNumber)
    }

    func test_cardNumber_messages_keepTheFieldErrorCode() {
        let codes = [TestData.CardNumbers.empty, TestData.CardNumbers.tooShort, TestData.CardNumbers.invalidLuhn]
            .map { cardNumberRule.validate($0).errorCode }

        XCTAssertEqual(codes, Array(repeating: "invalid-card_number", count: 3))
    }

    func test_cvv_empty_isRequired() {
        assertMessage(CVVRule(cardNetwork: .visa).validate(TestData.CVV.empty), CheckoutComponentsStrings.cvvRequired)
    }

    func test_cvv_wrongLengthForVisa_asksForThreeDigits() {
        assertMessage(CVVRule(cardNetwork: .visa).validate(TestData.CVV.tooShort), CheckoutComponentsStrings.cvvThreeDigits)
    }

    func test_cvv_nonNumeric_asksForThreeDigits() {
        assertMessage(CVVRule(cardNetwork: .visa).validate(TestData.CVV.nonNumeric), CheckoutComponentsStrings.cvvThreeDigits)
    }

    func test_cvv_wrongLengthForAmex_asksForFourDigits() {
        assertMessage(CVVRule(cardNetwork: .amex).validate(TestData.CVV.valid3Digit), CheckoutComponentsStrings.cvvFourDigits)
    }

    func test_expiry_empty_isRequired() {
        let (month, year) = TestData.ExpiryDates.empty

        assertMessage(validateExpiry(month: month, year: year), CheckoutComponentsStrings.expiryDateRequired)
    }

    func test_expiry_monthOutOfRange_isMonthInvalid() {
        let (month, year) = TestData.ExpiryDates.invalidMonth

        assertMessage(validateExpiry(month: month, year: year), CheckoutComponentsStrings.expiryMonthInvalid)
    }

    func test_expiry_lettersInMonth_isMonthInvalid() {
        assertMessage(
            validateExpiry(month: TestData.ExpiryDates.lettersMonth, year: TestData.ExpiryDates.year30),
            CheckoutComponentsStrings.expiryMonthInvalid
        )
    }

    func test_expiry_oneDigitYear_isYearInvalid() {
        assertMessage(
            validateExpiry(month: TestData.ExpiryDates.december, year: TestData.ExpiryDates.oneDigitYear),
            CheckoutComponentsStrings.expiryYearInvalid
        )
    }

    func test_expiry_missingYear_isYearInvalid() {
        assertMessage(
            validateExpiry(month: TestData.ExpiryDates.december, year: TestData.ExpiryDates.empty.1),
            CheckoutComponentsStrings.expiryYearInvalid
        )
    }

    func test_expiry_pastDate_isExpired() {
        let (month, year) = TestData.ExpiryDates.expired

        assertMessage(validateExpiry(month: month, year: year), CheckoutComponentsStrings.formErrorCardExpired)
    }

    func test_cardholderName_empty_isRequired() {
        assertMessage(
            CardholderNameRule().validate(TestData.CardholderNames.empty),
            CheckoutComponentsStrings.cardholderNameRequired
        )
    }

    func test_cardholderName_tooShort_isLength() {
        assertMessage(
            CardholderNameRule().validate(TestData.CardholderNames.tooShort),
            CheckoutComponentsStrings.formErrorCardHolderNameLength
        )
    }

    private func validateExpiry(month: String, year: String) -> ValidationResult {
        ExpiryDateRule().validate(ExpiryDateInput(month: month, year: year))
    }

    private func assertMessage(
        _ result: ValidationResult,
        _ expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertFalse(result.isValid, file: file, line: line)
        XCTAssertEqual(result.errorMessage, expected, file: file, line: line)
    }
}
