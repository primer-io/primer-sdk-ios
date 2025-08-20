//
//  PrimerRawCardDataManagerCardNumberTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class PrimerRawCardDataManagerCardNumberTests: XCTestCase {
    override func setUp() {
        SDKSessionHelper.setUp()
    }

    override func tearDown() {
        SDKSessionHelper.tearDown()
    }

    func test_invalid_cardnumber_in_raw_card_data_1() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/2040",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        rawCardData.cardNumber = "42424242424242421"

        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error
        }
    }

    func test_invalid_cardnumber_in_raw_card_data_2() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/2040",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        rawCardData.cardNumber = "424242424242424211"

        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error
        }
    }

    func test_invalid_cardnumber_in_raw_card_data_3() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/2040",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        rawCardData.cardNumber = "424242424242424212345"

        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error
        }
    }

    func test_invalid_cardnumber_in_raw_card_data_4() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/2040",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        rawCardData.cardNumber = ""

        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error
        }
    }
}
