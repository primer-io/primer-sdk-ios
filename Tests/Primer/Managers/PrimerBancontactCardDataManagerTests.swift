//
//  PrimerBancontactCardDataManagerTests.swift
//  Debug App Tests
//
//  Created by Evangelos on 13/1/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class PrimerBancontactCardDataManagerTests: XCTestCase {

    private static let expectationTimeout = 5.0

    func test_valid_raw_bancontact_card_data() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerBancontactCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.last!,
            expiryDate: "03/2030",
            cardholderName: "John Smith")

        let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

        firstly {
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            exp.fulfill()
        }
        .catch { _ in
            XCTAssert(false, "Card data should pass validation")
            exp.fulfill()
        }

        wait(for: [exp], timeout: Self.expectationTimeout)
    }

    // We are making the below tests as well to make sure that the standards validation of simple card data passes

    func test_valid_raw_card_data() throws {
        let validCardDataSet: [PrimerBancontactCardData] = [
            PrimerBancontactCardData(
                cardNumber: Constants.testCardNumbers[.visa]!.randomElement()!,
                expiryDate: "02/2040",
                cardholderName: "John Smith"
            ),
            PrimerBancontactCardData(
                cardNumber: Constants.testCardNumbers[.visa]!.randomElement()!,
                expiryDate: "12/2035",
                cardholderName: "Alice Doe"
            ),
            PrimerBancontactCardData(
                cardNumber: Constants.testCardNumbers[.visa]!.randomElement()!,
                expiryDate: "01/2050",
                cardholderName: "Bob Example"
            )
        ]

        let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

        for cardData in validCardDataSet {
            let exp = expectation(description: "Await validation for card \(cardData)")
            firstly {
                tokenizationBuilder.validateRawData(cardData)
            }
            .done { _ in
                exp.fulfill()
            }
            .catch { error in
                XCTFail("Card data should pass validation, but failed with error: \(error.localizedDescription)")
                exp.fulfill()
            }
            wait(for: [exp], timeout: Self.expectationTimeout)
        }
    }

    func test_valid_raw_card_data_async() async throws {
        let validCardDataSet: [PrimerBancontactCardData] = [
            PrimerBancontactCardData(
                cardNumber: Constants.testCardNumbers[.visa]!.randomElement()!,
                expiryDate: "02/2040",
                cardholderName: "John Smith"
            ),
            PrimerBancontactCardData(
                cardNumber: Constants.testCardNumbers[.visa]!.randomElement()!,
                expiryDate: "12/2035",
                cardholderName: "Alice Doe"
            ),
            PrimerBancontactCardData(
                cardNumber: Constants.testCardNumbers[.visa]!.randomElement()!,
                expiryDate: "01/2050",
                cardholderName: "Bob Example"
            )
        ]

        let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

        for cardData in validCardDataSet {
            do {
                try await tokenizationBuilder.validateRawData(cardData)
            } catch {
                XCTFail("Expected card data to pass validation, but it failed with error: \(error.localizedDescription)")
            }
        }
    }

    func test_invalid_cardnumber_in_raw_card_data() throws {
        let invalidCardNumbers = [
            "42424242424242421",
            "424242424242424211",
            "424242424242424212345",
            ""
        ]

        let rawCardData = PrimerBancontactCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/2040",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

        for cardNumber in invalidCardNumbers {
            let exp = expectation(description: "Await validation for card number '\(cardNumber)'")
            rawCardData.cardNumber = cardNumber
            firstly {
                tokenizationBuilder.validateRawData(rawCardData)
            }
            .done {
                XCTAssert(false, "Card data with card number '\(cardNumber)' should not pass validation")
                exp.fulfill()
            }
            .catch { _ in
                exp.fulfill()
            }
            wait(for: [exp], timeout: Self.expectationTimeout)
        }
    }

    func test_invalid_cardnumber_in_raw_card_data_async() async throws {
        let invalidCardNumbers = [
            "42424242424242421",
            "424242424242424211",
            "424242424242424212345",
            ""
        ]

        let rawCardData = PrimerBancontactCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/2040",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

        for cardNumber in invalidCardNumbers {
            rawCardData.cardNumber = cardNumber
            do {
                try await tokenizationBuilder.validateRawData(rawCardData)
                XCTFail("Card data with card number '\(cardNumber)' should not pass validation")
            } catch {
                XCTAssertNotNil(error, "Expected an error when validating invalid card number '\(cardNumber)'")
            }
        }
    }

    func test_invalid_expiry_date_in_raw_card_data() throws {
        let invalidExpiryDates = [
            "02/204",    // too short
            "",          // empty
            "a",         // single letter
            "abcdefg",   // random letters
            "ab/cdef",   // letters with slash
            "1",         // single digit
            "01",        // two digits
            "1234567",   // too long
            "01/",       // incomplete
            "12/30",     // short year
            "02/1234",   // invalid year
            "02/2030a",  // extra char
            "02/2O30",   // letter O instead of zero
            "02/2020",   // past year
            "02/2a5"     // invalid format
        ]

        let rawCardData = PrimerBancontactCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.randomElement()!,
            expiryDate: "02/2040",
            cardholderName: "John Smith"
        )
        let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

        for expiry in invalidExpiryDates {
            let exp = expectation(description: "Await validation for expiry '\(expiry)'")
            rawCardData.expiryDate = expiry
            firstly {
                tokenizationBuilder.validateRawData(rawCardData)
            }
            .done {
                XCTFail("Card data with expiry '\(expiry)' should not pass validation")
                exp.fulfill()
            }
            .catch { _ in
                exp.fulfill()
            }
            wait(for: [exp], timeout: Self.expectationTimeout)
        }
    }

    func test_invalid_expiry_date_in_raw_card_data_async() async throws {
        let invalidExpiryDates = [
            "02/204",    // too short
            "",          // empty
            "a",         // single letter
            "abcdefg",   // random letters
            "ab/cdef",   // letters with slash
            "1",         // single digit
            "01",        // two digits
            "1234567",   // too long
            "01/",       // incomplete
            "12/30",     // short year
            "02/1234",   // invalid year
            "02/2030a",  // extra char
            "02/2O30",   // letter O instead of zero
            "02/2020",   // past year
            "02/2a5"     // invalid format
        ]

        let rawCardData = PrimerBancontactCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.randomElement()!,
            expiryDate: "02/2040",
            cardholderName: "John Smith"
        )
        let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

        for expiry in invalidExpiryDates {
            rawCardData.expiryDate = expiry
            do {
                try await tokenizationBuilder.validateRawData(rawCardData)
                XCTFail("Card data with expiry '\(expiry)' should not pass validation")
            } catch {
                XCTAssertNotNil(error, "Expected an error when validating invalid expiry date '\(expiry)'")
            }
        }
    }
}
