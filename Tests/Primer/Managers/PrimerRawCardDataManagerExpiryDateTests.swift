//
//  PrimerRawCardDataManagerExpiryDateTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class PrimerRawCardDataManagerExpiryDateTests: XCTestCase {
    override func setUp() {
        SDKSessionHelper.setUp()
    }

    override func tearDown() {
        SDKSessionHelper.tearDown()
    }

    func test_invalid_expiry_date_in_raw_card_data_1() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error
        }
    }

    func test_invalid_expiry_date_in_raw_card_data_2() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        rawCardData.expiryDate = "a"

        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error
        }
    }

    func test_invalid_expiry_date_in_raw_card_data_3() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        rawCardData.expiryDate = "1"

        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error
        }
    }

    func test_invalid_expiry_date_in_raw_card_data_4() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        rawCardData.expiryDate = ""

        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error
        }
    }

    func test_invalid_expiry_date_in_raw_card_data_5() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        rawCardData.expiryDate = "13"

        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error
        }
    }

    func test_invalid_expiry_date_in_raw_card_data_6() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        rawCardData.expiryDate = "019"

        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error
        }
    }

    func test_invalid_expiry_date_in_raw_card_data_7() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        rawCardData.expiryDate = "02/"

        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error
        }
    }

    func test_invalid_expiry_date_in_raw_card_data_8() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        rawCardData.expiryDate = "02/30"

        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            // With MM/YY support, "02/30" should be valid as it converts to "02/2030"
        } catch {
            XCTFail("Card data should pass validation with MM/YY format")
        }
    }

    func test_invalid_expiry_date_in_raw_card_data_9() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        rawCardData.expiryDate = "02/2a5"

        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error
        }
    }

    func test_invalid_expiry_date_in_raw_card_data_10() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        rawCardData.expiryDate = "02/2019"

        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error
        }
    }
}
