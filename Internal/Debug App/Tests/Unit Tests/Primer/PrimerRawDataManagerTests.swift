//
//  PrimerRawDataManagerTests.swift
//  ExampleAppTests
//
//  Created by Evangelos on 26/9/22.
//  Copyright © 2022 Primer API Ltd. All rights reserved.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class PrimerRawDataManagerTests: XCTestCase {
    
    let testCardNumbers: [CardNetwork: [String]] = [
        .amex: [
            "3700 0000 0000 002",
            "3700 0000 0100 018"
        ],
        .diners: [
            "3600 6666 3333 44",
            "3607 0500 0010 20"
        ],
        .discover: [
            "6011 6011 6011 6611",
            "6445 6445 6445 6445"
        ],
        .jcb: [
            "3569 9900 1009 5841"
        ],
        .maestro: [
            "6771 7980 2100 0008"
        ],
        .masterCard: [
            "2222 4000 7000 0005",
            "5555 3412 4444 1115",
            "5577 0000 5577 0004",
            "5555 4444 3333 1111",
            "2222 4107 4036 0010",
            "5555 5555 5555 4444"
        ],
        .visa: [
            "4111 1111 4555 1142",
            "4988 4388 4388 4305",
            "4166 6766 6766 6746",
            "4646 4646 4646 4644",
            "4000 6200 0000 0007",
            "4000 0600 0000 0006",
            "4293 1891 0000 0008",
            "4988 0800 0000 0000",
            "4111 1111 1111 1111",
            "4444 3333 2222 1111",
            "4001 5900 0000 0001",
            "4000 1800 0000 0002"
        ]
    ]
    
    func test_valid_raw_card_data() throws {
        let rawCardData = PrimerCardData(
            cardNumber: testCardNumbers[.visa]!.first!,
            expiryMonth: "02",
            expiryYear: "2040",
            cvv: "123",
            cardholderName: "John Smith")
        
        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")
        
        firstly {
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            // Continue
        }
        .catch { _ in
            XCTAssert(false, "Card data should pass validation")
        }
    }
    
    func test_invalid_cardnumber_in_raw_card_data() throws {
        let rawCardData = PrimerCardData(
            cardNumber: testCardNumbers[.visa]!.first!,
            expiryMonth: "02",
            expiryYear: "2040",
            cvv: "123",
            cardholderName: "John Smith")
        
        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")
        
        firstly {
            rawCardData.cardNumber = "42424242424242421"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly {
            rawCardData.cardNumber = "424242424242424211"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly {
            rawCardData.cardNumber = "424242424242424212345"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly {
            rawCardData.cardNumber = ""
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
    }
    
    func test_invalid_expiry_date_in_raw_card_data() throws {
        let rawCardData = PrimerCardData(
            cardNumber: testCardNumbers[.visa]!.first!,
            expiryMonth: "02",
            expiryYear: "2040",
            cvv: "123",
            cardholderName: "John Smith")
        
        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")
        
        firstly {
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly {
            rawCardData.expiryMonth = "a"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly {
            rawCardData.expiryMonth = "1"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }

        firstly {
            rawCardData.expiryMonth = ""
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }

        firstly {
            rawCardData.expiryMonth = "13"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }

        firstly {
            rawCardData.expiryMonth = "019"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }

        firstly {
            rawCardData.expiryMonth = "02"
            rawCardData.expiryYear  = ""
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly {
            rawCardData.expiryYear  = "25"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }

        firstly {
            rawCardData.expiryYear  = "2a5"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }

        firstly {
            rawCardData.expiryYear  = "2019"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
    }
    
    func test_invalid_cvv_in_raw_card_data() throws {
        let rawCardData = PrimerCardData(
            cardNumber: testCardNumbers[.visa]!.first!,
            expiryMonth: "99",
            expiryYear: "2040",
            cvv: "12345",
            cardholderName: "John Smith")

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly {
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly {
            rawCardData.cardNumber = testCardNumbers[.visa]!.first!
            rawCardData.cvv = "1234"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }


        firstly {
            rawCardData.cardNumber = testCardNumbers[.visa]!.first!
            rawCardData.cvv = "1234"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }

        firstly {
            rawCardData.cardNumber = testCardNumbers[.masterCard]!.first!
            rawCardData.cvv = "1234"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }

        firstly {
            rawCardData.cardNumber = testCardNumbers[.amex]!.first!
            rawCardData.cvv = "123"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
    }
}

#endif
