//
//  PrimerRawCardDataManagerExpiryDateTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class PrimerRawCardDataManagerExpiryDateTests: XCTestCase {
    private let validationTimeout = 5.0

    override func setUp() {
        SDKSessionHelper.setUp()
    }

    override func tearDown() {
        SDKSessionHelper.tearDown()
    }

    func test_invalid_expiry_date_in_raw_card_data_1() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly { () -> Promise<Void> in
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

    func test_invalid_expiry_date_in_raw_card_data_2() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "a"
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

    func test_invalid_expiry_date_in_raw_card_data_3() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "1"
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

    func test_invalid_expiry_date_in_raw_card_data_4() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = ""
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

    func test_invalid_expiry_date_in_raw_card_data_5() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "13"
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

    func test_invalid_expiry_date_in_raw_card_data_6() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "019"
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

    func test_invalid_expiry_date_in_raw_card_data_7() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "02/"
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

    func test_invalid_expiry_date_in_raw_card_data_8() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")
        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "02/30"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            // With MM/YY support, "02/30" should be valid as it converts to "02/2030"
            exp.fulfill()
        }
        .catch { _ in
            XCTAssert(false, "Card data should pass validation with MM/YY format")
            exp.fulfill()
        }

        wait(for: [exp], timeout: validationTimeout)
    }

    func test_invalid_expiry_date_in_raw_card_data_9() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "02/2a5"
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

    func test_invalid_expiry_date_in_raw_card_data_10() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "02/2019"
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
