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
        
        do {
            try rawCardData.validate()
            // Continue
        } catch {
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
        
        do {
            rawCardData.cardNumber = "42424242424242421"
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
        
        do {
            rawCardData.cardNumber = "424242424242424211"
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
        
        do {
            rawCardData.cardNumber = "424242424242424212345"
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
        
        do {
            rawCardData.cardNumber = ""
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
    }
    
    func test_invalid_expiry_date_in_raw_card_data() throws {
        let rawCardData = PrimerCardData(
            cardNumber: testCardNumbers[.visa]!.first!,
            expiryMonth: "02",
            expiryYear: "2040",
            cvv: "123",
            cardholderName: "John Smith")
        
        do {
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
        
        do {
            rawCardData.expiryMonth = "a"
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
        
        do {
            rawCardData.expiryMonth = "1"
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
        
        do {
            rawCardData.expiryMonth = ""
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
        
        do {
            rawCardData.expiryMonth = "13"
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
        
        do {
            rawCardData.expiryMonth = "019"
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
        
        do {
            rawCardData.expiryMonth = "02"
            rawCardData.expiryYear = ""
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
        
        do {
            rawCardData.expiryYear = "25"
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
        
        do {
            rawCardData.expiryYear = "2a5"
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
        
        do {
            rawCardData.expiryYear = "2019"
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
    }
    
    func test_invalid_cvv_in_raw_card_data() throws {
        let rawCardData = PrimerCardData(
            cardNumber: testCardNumbers[.visa]!.first!,
            expiryMonth: "99",
            expiryYear: "2040",
            cvv: "12345",
            cardholderName: "John Smith")
        
        do {
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
        
        do {
            rawCardData.cardNumber = testCardNumbers[.visa]!.first!
            rawCardData.cvv = "1234"
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
        
        do {
            rawCardData.cardNumber = testCardNumbers[.visa]!.first!
            rawCardData.cvv = "1234"
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
        
        do {
            rawCardData.cardNumber = testCardNumbers[.masterCard]!.first!
            rawCardData.cvv = "1234"
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
        
        do {
            rawCardData.cardNumber = testCardNumbers[.amex]!.first!
            rawCardData.cvv = "123"
            try rawCardData.validate()
            XCTAssert(false, "Card data should not pass validation")
        } catch {

        }
    }
}

#endif
