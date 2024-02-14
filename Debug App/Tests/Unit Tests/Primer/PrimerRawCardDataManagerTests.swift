//
//  PrimerRawDataManagerTests.swift
//  ExampleAppTests
//
//  Created by Evangelos on 26/9/22.
//  Copyright © 2022 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class PrimerRawCardDataManagerTests: XCTestCase {

    static let validationTimeout = 1.0
    
    override func setUp() {
        SDKSessionHelper.setUp()
    }
    
    override func tearDown() {
        SDKSessionHelper.tearDown()
    }
    
    func test_invalid_cardnumber_in_raw_card_data() throws {
        var exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/2040",
            cvv: "123",
            cardholderName: "John Smith")

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly { () -> Promise<Void> in
            rawCardData.cardNumber = "42424242424242421"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: Self.validationTimeout)
        exp = expectation(description: "Await validation")

        firstly { () -> Promise<Void> in
            rawCardData.cardNumber = "424242424242424211"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: Self.validationTimeout)
        exp = expectation(description: "Await validation")

        firstly { () -> Promise<Void> in
            rawCardData.cardNumber = "424242424242424212345"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: Self.validationTimeout)
        exp = expectation(description: "Await validation")

        firstly { () -> Promise<Void> in
            rawCardData.cardNumber = ""
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: Self.validationTimeout)
    }

    func test_invalid_expiry_date_in_raw_card_data() throws {
        var exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/204",
            cvv: "123",
            cardholderName: "John Smith")

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

        wait(for: [exp], timeout: Self.validationTimeout)
        exp = expectation(description: "Await validation")

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

        wait(for: [exp], timeout: Self.validationTimeout)
        exp = expectation(description: "Await validation")

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

        wait(for: [exp], timeout: Self.validationTimeout)
        exp = expectation(description: "Await validation")
        
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

        wait(for: [exp], timeout: Self.validationTimeout)
        exp = expectation(description: "Await validation")
        
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

        wait(for: [exp], timeout: Self.validationTimeout)
        exp = expectation(description: "Await validation")
        
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

        wait(for: [exp], timeout: Self.validationTimeout)
        exp = expectation(description: "Await validation")
        
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

        wait(for: [exp], timeout: Self.validationTimeout)
        exp = expectation(description: "Await validation")

        firstly { () -> Promise<Void> in
            rawCardData.expiryDate  = "02/25"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: Self.validationTimeout)
        exp = expectation(description: "Await validation")
        
        firstly { () -> Promise<Void> in
            rawCardData.expiryDate  = "02/2a5"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: Self.validationTimeout)
        exp = expectation(description: "Await validation")
        
        firstly { () -> Promise<Void> in
            rawCardData.expiryDate  = "02/2019"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: Self.validationTimeout)
    }

    func test_invalid_cvv_in_raw_card_data() throws {
        var exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "99/2040",
            cvv: "12345",
            cardholderName: "John Smith")
        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")
        
        firstly {
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: Self.validationTimeout)
        exp = expectation(description: "Await validation")
        
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
        
        wait(for: [exp], timeout: Self.validationTimeout)
        exp = expectation(description: "Await validation")
        
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
        
        wait(for: [exp], timeout: Self.validationTimeout)
        exp = expectation(description: "Await validation")

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
        
        wait(for: [exp], timeout: Self.validationTimeout)
        exp = expectation(description: "Await validation")

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

        wait(for: [exp], timeout: Self.validationTimeout)
    }
}
