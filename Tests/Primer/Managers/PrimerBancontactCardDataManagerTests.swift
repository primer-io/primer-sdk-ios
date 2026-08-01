//
//  PrimerBancontactCardDataManagerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
@testable import PrimerSDK
import XCTest

class PrimerBancontactCardDataManagerTests: XCTestCase {

    // MARK: - makeRequestBodyWithRawData

    func test_makeRequestBody_withBancontactCardData_shouldBuildInstrument() async throws {
        try await SDKSessionHelper.test(withPaymentMethods: [Mocks.PaymentMethods.adyenBancontactCardPaymentMethod]) {
            // Given
            let rawCardData = PrimerBancontactCardData(
                cardNumber: "4242 4242 4242 4242",
                expiryDate: "03/2030",
                cardholderName: "John Smith"
            )
            let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

            // When
            let body = try await tokenizationBuilder.makeRequestBodyWithRawData(rawCardData)

            // Then
            let instrument = try XCTUnwrap(body.paymentInstrument as? CardOffSessionPaymentInstrument)
            XCTAssertEqual(instrument.number, "4242424242424242")
            XCTAssertEqual(instrument.expirationMonth, "03")
            XCTAssertEqual(instrument.expirationYear, "2030")
            XCTAssertEqual(instrument.cardholderName, "John Smith")
            XCTAssertEqual(instrument.paymentMethodType, "ADYEN_BANCONTACT_CARD")
        }
    }

    func test_makeRequestBody_withTwoDigitYear_shouldNormalizeToFourDigits() async throws {
        try await SDKSessionHelper.test(withPaymentMethods: [Mocks.PaymentMethods.adyenBancontactCardPaymentMethod]) {
            // Given - validation accepts MM/YY, so the builder must expand it rather than send "30"
            let rawCardData = PrimerBancontactCardData(
                cardNumber: "4242424242424242",
                expiryDate: "03/30",
                cardholderName: "John Smith"
            )
            let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

            // When
            let body = try await tokenizationBuilder.makeRequestBodyWithRawData(rawCardData)

            // Then
            let instrument = try XCTUnwrap(body.paymentInstrument as? CardOffSessionPaymentInstrument)
            XCTAssertEqual(instrument.expirationMonth, "03")
            XCTAssertEqual(instrument.expirationYear, "2030")
        }
    }

    func test_makeRequestBody_withPrimerCardData_shouldThrow() async throws {
        try await SDKSessionHelper.test(withPaymentMethods: [Mocks.PaymentMethods.adyenBancontactCardPaymentMethod]) {
            // Given - PrimerCardData is a sibling of PrimerBancontactCardData, not an accepted input here
            let rawCardData = PrimerCardData(
                cardNumber: "4242424242424242",
                expiryDate: "03/2030",
                cvv: "123",
                cardholderName: "John Smith"
            )
            let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

            // When & Then
            do {
                _ = try await tokenizationBuilder.makeRequestBodyWithRawData(rawCardData)
                XCTFail("Expected makeRequestBodyWithRawData to throw for PrimerCardData")
            } catch {
                XCTAssertEqual((error as? PrimerError)?.errorId, "invalid-value")
            }
        }
    }

    func test_makeRequestBody_withMixedCaseAndSpacedCardNumber_shouldSanitize() async throws {
        try await SDKSessionHelper.test(withPaymentMethods: [Mocks.PaymentMethods.adyenBancontactCardPaymentMethod]) {
            // Given
            let rawCardData = PrimerBancontactCardData(
                cardNumber: "4871 0499 9999 9910",
                expiryDate: "12/2031",
                cardholderName: "John Smith"
            )
            let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

            // When
            let body = try await tokenizationBuilder.makeRequestBodyWithRawData(rawCardData)

            // Then
            let instrument = try XCTUnwrap(body.paymentInstrument as? CardOffSessionPaymentInstrument)
            XCTAssertEqual(instrument.number, "4871049999999910")
            XCTAssertEqual(instrument.expirationMonth, "12")
            XCTAssertEqual(instrument.expirationYear, "2031")
        }
    }

    func test_makeRequestBody_withThreeDigitYear_shouldThrowInvalidExpiryDate() async throws {
        try await SDKSessionHelper.test(withPaymentMethods: [Mocks.PaymentMethods.adyenBancontactCardPaymentMethod]) {
            // Given - the API requires a 4-digit year, so a 3-digit one cannot be normalized
            let rawCardData = PrimerBancontactCardData(
                cardNumber: "4242424242424242",
                expiryDate: "03/203",
                cardholderName: "John Smith"
            )
            let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

            // When & Then
            do {
                _ = try await tokenizationBuilder.makeRequestBodyWithRawData(rawCardData)
                XCTFail("Expected makeRequestBodyWithRawData to throw for a 3-digit year")
            } catch {
                XCTAssertEqual((error as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            }
        }
    }

    func test_makeRequestBody_withNonNumericYear_shouldThrowInvalidExpiryDate() async throws {
        try await SDKSessionHelper.test(withPaymentMethods: [Mocks.PaymentMethods.adyenBancontactCardPaymentMethod]) {
            // Given
            let rawCardData = PrimerBancontactCardData(
                cardNumber: "4242424242424242",
                expiryDate: "03/2O30",
                cardholderName: "John Smith"
            )
            let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

            // When & Then
            do {
                _ = try await tokenizationBuilder.makeRequestBodyWithRawData(rawCardData)
                XCTFail("Expected makeRequestBodyWithRawData to throw for a non-numeric year")
            } catch {
                XCTAssertEqual((error as? PrimerValidationError)?.errorId, "invalid-expiry-date")
            }
        }
    }

    func test_makeRequestBody_withUnconfiguredPaymentMethod_shouldThrow() async throws {
        try await SDKSessionHelper.test(withPaymentMethods: [Mocks.PaymentMethods.paymentCardPaymentMethod]) {
            // Given - Bancontact is absent from the client session
            let rawCardData = PrimerBancontactCardData(
                cardNumber: "4242424242424242",
                expiryDate: "03/2030",
                cardholderName: "John Smith"
            )
            let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

            // When & Then
            do {
                _ = try await tokenizationBuilder.makeRequestBodyWithRawData(rawCardData)
                XCTFail("Expected makeRequestBodyWithRawData to throw when the method is not configured")
            } catch {
                XCTAssertEqual((error as? PrimerError)?.errorId, "unsupported-payment-method-type")
            }
        }
    }

    func test_requiredInputElementTypes_shouldNotIncludeCVV() {
        // Bancontact has no security code — 3DS is the authentication step instead.
        let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

        XCTAssertEqual(tokenizationBuilder.requiredInputElementTypes, [.cardNumber, .expiryDate, .cardholderName])
        XCTAssertFalse(tokenizationBuilder.requiredInputElementTypes.contains(.cvv))
    }

    func test_makeRequestBody_withExpiryDateMissingSeparator_shouldThrow() async throws {
        try await SDKSessionHelper.test(withPaymentMethods: [Mocks.PaymentMethods.adyenBancontactCardPaymentMethod]) {
            // Given
            let rawCardData = PrimerBancontactCardData(
                cardNumber: "4242424242424242",
                expiryDate: "0330",
                cardholderName: "John Smith"
            )
            let tokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: "ADYEN_BANCONTACT_CARD")

            // When & Then
            do {
                _ = try await tokenizationBuilder.makeRequestBodyWithRawData(rawCardData)
                XCTFail("Expected makeRequestBodyWithRawData to throw for a separator-less expiry date")
            } catch {
                XCTAssertEqual((error as? PrimerError)?.errorId, "invalid-value")
            }
        }
    }

    // MARK: - validateRawData

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
