//
//  PrimerBancontactCardDataManagerTests.swift
//  Debug App Tests
//
//  Created by Evangelos on 13/1/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class PrimerBancontactCardDataManagerTests: XCTestCase {
    
    func test_valid_raw_bancontact_card_data() throws {
        let rawCardData = PrimerBancontactCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.last!,
            expiryDate: "03/2030",
            cardholderName: "John Smith")
        
        let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")
        
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
    
    // We are making the below tests as well to make sure that the standards validation of simple card data passes
        
    func test_valid_raw_card_data() throws {
        
        let rawCardData = PrimerBancontactCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.randomElement()!,
            expiryDate: "02/2040",
            cardholderName: "John Smith")
        
        let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")
        
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
        let rawCardData = PrimerBancontactCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/2040",
            cardholderName: "John Smith")
        
        let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")
        
        firstly { () -> Promise<Void> in
            rawCardData.cardNumber = "42424242424242421"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly { () -> Promise<Void> in
            rawCardData.cardNumber = "424242424242424211"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly { () -> Promise<Void> in
            rawCardData.cardNumber = "424242424242424212345"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly { () -> Promise<Void> in
            rawCardData.cardNumber = ""
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
    }
    
    func test_invalid_expiry_date_in_raw_card_data() throws {
        let rawCardData = PrimerBancontactCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.randomElement()!,
            expiryDate: "02/2040",
            cardholderName: "John Smith")
        
        let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")
        
        firstly {
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done { _ in
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = ""
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }

        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "a"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "abcdefg"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "ab/cdef"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "1"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "01"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "1234567"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "01/"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "12/30"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }

        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "02/1234"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }

        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "02/2030a"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
        
        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "02/2O30"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }

        firstly { () -> Promise<Void> in
            rawCardData.expiryDate = "02/2020"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }

        firstly { () -> Promise<Void> in
            rawCardData.expiryDate  = "02/2a5"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
    }
}

#endif

