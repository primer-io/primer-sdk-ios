//
//  PrimerRawCardDataManagerCVVTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class PrimerRawCardDataManagerCVVTests: XCTestCase {
    private let validationTimeout = 5.0

    override func setUp() {
        SDKSessionHelper.setUp()
    }

    override func tearDown() {
        SDKSessionHelper.tearDown()
    }

    func test_invalid_cvv_in_raw_card_data_1() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "99/2040",
            cvv: "12345",
            cardholderName: "John Smith"
        )
        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly {
            tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: validationTimeout)
    }

    func test_invalid_cvv_in_raw_card_data_2() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "99/2040",
            cvv: "12345",
            cardholderName: "John Smith"
        )
        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly { () -> Promise<Void> in
            rawCardData.cardNumber = Constants.testCardNumbers[.visa]!.first!
            rawCardData.cvv = "1234"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: validationTimeout)
    }

    func test_invalid_cvv_in_raw_card_data_3() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "99/2040",
            cvv: "12345",
            cardholderName: "John Smith"
        )
        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly { () -> Promise<Void> in
            rawCardData.cardNumber = Constants.testCardNumbers[.visa]!.first!
            rawCardData.cvv = "1234"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: validationTimeout)
    }

    func test_invalid_cvv_in_raw_card_data_4() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "99/2040",
            cvv: "12345",
            cardholderName: "John Smith"
        )
        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly { () -> Promise<Void> in
            rawCardData.cardNumber = Constants.testCardNumbers[.masterCard]!.first!
            rawCardData.cvv = "1234"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: validationTimeout)
    }

    func test_invalid_cvv_in_raw_card_data_5() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "99/2040",
            cvv: "12345",
            cardholderName: "John Smith"
        )
        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly { () -> Promise<Void> in
            rawCardData.cardNumber = Constants.testCardNumbers[.amex]!.first!
            rawCardData.cvv = "123"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: validationTimeout)
    }
}
