//
//  PrimerBancontactCardDataManagerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

class PrimerBancontactCardDataManagerTests: XCTestCase {

    func test_validateRawData_withValidBancontactCardData_shouldSucceed() async throws {
        // Given
        let rawCardData = PrimerBancontactCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.last!,
            expiryDate: "03/2030",
            cardholderName: "John Smith"
        )
        let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

        // When & Then
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            // Expected to succeed without throwing
        } catch {
            XCTFail("Card data should pass validation")
        }
    }

    // We are making the below tests as well to make sure that the standards validation of simple card data passes

    func test_validateRawData_withValidCardData_shouldSucceed() async throws {
        // Given
        let rawCardData = PrimerBancontactCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.randomElement()!,
            expiryDate: "02/2040",
            cardholderName: "John Smith"
        )
        let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

        // When & Then
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            // Expected to succeed without throwing
        } catch {
            XCTFail("Card data should pass validation")
        }
    }

    func test_validateRawData_withInvalidCardNumbers_shouldFail() async throws {
        // Given
        let rawCardData = PrimerBancontactCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/2040",
            cardholderName: "John Smith"
        )
        let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

        // When & Then - Test invalid card number (too many digits)
        rawCardData.cardNumber = "42424242424242421"
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }

        // When & Then - Test invalid card number (extra digits)
        rawCardData.cardNumber = "424242424242424211"
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }

        // When & Then - Test invalid card number (way too many digits)
        rawCardData.cardNumber = "424242424242424212345"
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }

        // When & Then - Test empty card number
        rawCardData.cardNumber = ""
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }
    }

    func test_validateRawData_withInvalidExpiryDates_shouldFail() async throws {
        // Given
        let rawCardData = PrimerBancontactCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.randomElement()!,
            expiryDate: "02/204",
            cardholderName: "John Smith"
        )
        let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

        // When & Then - Test invalid expiry format (3-digit year)
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }

        // When & Then - Test empty expiry date
        rawCardData.expiryDate = ""
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }

        // When & Then - Test single character expiry
        rawCardData.expiryDate = "a"
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }

        // When & Then - Test random string expiry
        rawCardData.expiryDate = "abcdefg"
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }

        // When & Then - Test invalid format with slash
        rawCardData.expiryDate = "ab/cdef"
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }

        // When & Then - Test single digit
        rawCardData.expiryDate = "1"
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }

        // When & Then - Test two digits without slash
        rawCardData.expiryDate = "01"
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }

        // When & Then - Test too many digits
        rawCardData.expiryDate = "1234567"
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }

        // When & Then - Test incomplete format
        rawCardData.expiryDate = "01/"
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }

        // When & Then - Test MM/YY format (should be valid)
        rawCardData.expiryDate = "12/30"
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            // With MM/YY support, "12/30" should be valid as it converts to "12/2030"
        } catch {
            XCTFail("Card data should pass validation with MM/YY format")
        }

        // When & Then - Test invalid 4-digit year
        rawCardData.expiryDate = "02/1234"
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }

        // When & Then - Test expiry with extra character
        rawCardData.expiryDate = "02/2030a"
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }

        // When & Then - Test expiry with letter in year
        rawCardData.expiryDate = "02/2O30"
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }

        // When & Then - Test expired date
        rawCardData.expiryDate = "02/2020"
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }

        // When & Then - Test expiry with invalid character in year
        rawCardData.expiryDate = "02/2a5"
        do {
            try await tokenizationBuilder.validateRawData(rawCardData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }
    }
}
