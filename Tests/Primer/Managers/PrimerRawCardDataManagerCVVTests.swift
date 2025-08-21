//
//  PrimerRawCardDataManagerCVVTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class PrimerRawCardDataManagerCVVTests: XCTestCase {
    override func setUp() {
        SDKSessionHelper.setUp()
    }

    override func tearDown() {
        SDKSessionHelper.tearDown()
    }

    func test_invalid_cvv_in_raw_card_data_1() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "99/2040",
            cvv: "12345",
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

    func test_invalid_cvv_in_raw_card_data_2() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "99/2040",
            cvv: "12345",
            cardholderName: "John Smith"
        )
        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        rawCardData.cardNumber = Constants.testCardNumbers[.visa]!.first!
        rawCardData.cvv = "1234"

        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error
        }
    }

    func test_invalid_cvv_in_raw_card_data_3() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "99/2040",
            cvv: "12345",
            cardholderName: "John Smith"
        )
        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        rawCardData.cardNumber = Constants.testCardNumbers[.visa]!.first!
        rawCardData.cvv = "1234"

        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error
        }
    }

    func test_invalid_cvv_in_raw_card_data_4() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "99/2040",
            cvv: "12345",
            cardholderName: "John Smith"
        )
        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        rawCardData.cardNumber = Constants.testCardNumbers[.masterCard]!.first!
        rawCardData.cvv = "1234"

        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error
        }
    }

    func test_invalid_cvv_in_raw_card_data_5() async throws {
        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "99/2040",
            cvv: "12345",
            cardholderName: "John Smith"
        )
        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        rawCardData.cardNumber = Constants.testCardNumbers[.amex]!.first!
        rawCardData.cvv = "123"

        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error
        }
    }
}
