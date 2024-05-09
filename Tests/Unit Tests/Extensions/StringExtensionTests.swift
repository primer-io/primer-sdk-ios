//
//  StringExtensionTests.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 24/10/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

final class StringExtensionTests: XCTestCase {

    func testWithoutWhitespace() {
        XCTAssertEqual(" ".withoutWhiteSpace, "")
        XCTAssertEqual("    ".withoutWhiteSpace, "")
        XCTAssertEqual("a b".withoutWhiteSpace, "ab")
        XCTAssertEqual("    a    b    ".withoutWhiteSpace, "ab")
        XCTAssertEqual("4111 1234 9876 4321".withoutWhiteSpace, "4111123498764321")
        XCTAssertEqual("\t4111 1234 9876 4321\n".withoutWhiteSpace, "4111123498764321")
    }

    func testIsNumeric() {
        XCTAssertFalse("".isNumeric)
        XCTAssertFalse(" ".isNumeric)
        XCTAssertFalse("a".isNumeric)
        XCTAssertFalse("1a0".isNumeric)
        XCTAssertFalse("10 000".isNumeric)
        XCTAssertFalse("99,999,999".isNumeric)

        XCTAssertTrue("0".isNumeric)
        XCTAssertTrue("1".isNumeric)
        XCTAssertTrue("1000".isNumeric)
        XCTAssertTrue("1234567890".isNumeric)
    }

    func testIsValidCardNumber() {
        Constants.testCardNumbers.flatMap { $0.value }.forEach {
            XCTAssertTrue($0.isValidCardNumber)
        }

        XCTAssertFalse("".isValidCardNumber)
        XCTAssertFalse("abcd".isValidCardNumber)
        XCTAssertFalse("0".isValidCardNumber)
        XCTAssertFalse("0001 0001 0001 0001".isValidCardNumber) // Not Luhn-valid
    }

    func testIsHttpOrHttpsURL() {
        XCTAssertTrue("https://google.com".isHttpOrHttpsURL)
        XCTAssertTrue("http://google.com".isHttpOrHttpsURL)

        XCTAssertTrue("https://".isHttpOrHttpsURL)
        XCTAssertTrue("http://".isHttpOrHttpsURL)

        XCTAssertFalse("google.com".isHttpOrHttpsURL)
        XCTAssertFalse("not a url".isHttpOrHttpsURL)
    }

    func testWithoutNonNumericCharacters() {
        XCTAssertEqual("abcdefg123456".withoutNonNumericCharacters, "123456")
        XCTAssertEqual("a1b2c3e4f5g6".withoutNonNumericCharacters, "123456")
        XCTAssertEqual("00000".withoutNonNumericCharacters, "00000")
    }

    func testIsValidExpiryDate() {
        XCTAssertFalse("00/00".isValidExpiryDate)
        XCTAssertFalse("00/0000".isValidExpiryDate)
        XCTAssertFalse("99/2030".isValidExpiryDate)
        XCTAssertFalse("13/2030".isValidExpiryDate)
        XCTAssertFalse("01/23".isValidExpiryDate)
        XCTAssertFalse("01/23".isValidExpiryDate)
        XCTAssertFalse("12/2023".isValidExpiryDate)
        XCTAssertFalse("12/2030".isValidExpiryDate)

        XCTAssertTrue("01/28".isValidExpiryDate)
        XCTAssertTrue("12/30".isValidExpiryDate)
    }

    func testIsValidCVV() {
        // Four digit
        let fourDigitCVVNetworks = CardNetwork.allCases.filter { network in
            guard let validation = network.validation else { return false }
            return validation.code.length == 4
        }
        fourDigitCVVNetworks.forEach { network in
            XCTAssertTrue("1234".isValidCVV(cardNetwork: network))
            XCTAssertFalse("12".isValidCVV(cardNetwork: network))
            XCTAssertFalse("123".isValidCVV(cardNetwork: network))
            XCTAssertFalse("".isValidCVV(cardNetwork: network))
        }

        // Three digit
        let threeDigitCVVNetworks = CardNetwork.allCases.filter { network in
            guard let validation = network.validation else { return false }
            return validation.code.length == 3
        }
        threeDigitCVVNetworks.forEach { network in
            XCTAssertTrue("123".isValidCVV(cardNetwork: network))
            XCTAssertFalse("12".isValidCVV(cardNetwork: network))
            XCTAssertFalse("1234".isValidCVV(cardNetwork: network))
            XCTAssertFalse("".isValidCVV(cardNetwork: network))
        }

        // Unknown
        XCTAssertTrue("123".isValidCVV(cardNetwork: .unknown))
        XCTAssertFalse("123456".isValidCVV(cardNetwork: .unknown))
    }

    func testIsTypingValidCVV() {
        // Three digit
        let threeDigitCVVNetworks = CardNetwork.allCases.filter { network in
            guard let validation = network.validation else { return false }
            return validation.code.length == 3
        }
        threeDigitCVVNetworks.forEach { network in
            XCTAssertTrue("123".isTypingValidCVV(cardNetwork: network)!)
            XCTAssertNil("12".isTypingValidCVV(cardNetwork: network))
            XCTAssertEqual("1234".isTypingValidCVV(cardNetwork: network)!, false)
            XCTAssertNil("".isTypingValidCVV(cardNetwork: network))
        }

        // Four digit
        let fourDigitCVVNetworks = CardNetwork.allCases.filter { network in
            guard let validation = network.validation else { return false }
            return validation.code.length == 4
        }
        fourDigitCVVNetworks.forEach { network in
            XCTAssertTrue("1234".isTypingValidCVV(cardNetwork: network)!)
            XCTAssertNil("12".isTypingValidCVV(cardNetwork: network))
            XCTAssertTrue("123".isTypingValidCVV(cardNetwork: network)!)
            XCTAssertNil("".isTypingValidCVV(cardNetwork: network))
        }

        // Unknown
        XCTAssertTrue("123".isTypingValidCVV(cardNetwork: .unknown)!)
        XCTAssertFalse("123456".isTypingValidCVV(cardNetwork: .unknown)!)
    }

    func testIsValidNonDecimalString() {
        XCTAssertFalse("".isValidNonDecimalString)
        XCTAssertFalse("12345".isValidNonDecimalString)
        XCTAssertFalse("abcde12345".isValidNonDecimalString)
        XCTAssertTrue("abcde".isValidNonDecimalString)
        XCTAssertTrue("John Doe".isValidNonDecimalString)
    }

    func testIsValidPostalCode() {
        XCTAssertTrue("AB12 3CD".isValidPostalCode)
        XCTAssertTrue("EC4M 7RF".isValidPostalCode)
        XCTAssertTrue("L1 1EJ".isValidPostalCode)
        XCTAssertTrue("12345".isValidPostalCode)
        XCTAssertTrue("12345AB".isValidPostalCode)
        XCTAssertTrue("12345 AB".isValidPostalCode)
        XCTAssertTrue("AB-123-45".isValidPostalCode)
        XCTAssertTrue("AB-123-45".isValidPostalCode)

        XCTAssertFalse("".isValidPostalCode)
        XCTAssertFalse("¡€#¢∞§¶•".isValidPostalCode)
    }

    func testIsValidLuhn() {
        // Sanity cases
        XCTAssertTrue("0".isValidLuhn)
        XCTAssertFalse("1".isValidLuhn)

        // Invalid numbers
        XCTAssertFalse("0000 0000 0000 0001".isValidLuhn)
        XCTAssertFalse("4111 1212 1212 1212".isValidLuhn)

        // VISA - Valid w/ and w/o spaces
        XCTAssertTrue("4716 4576 2661 6808".isValidLuhn)
        XCTAssertTrue("4716457626616808".isValidLuhn)

        // Discover
        XCTAssertTrue("4929338582262071".isValidLuhn)
        XCTAssertTrue("4024007183599989533".isValidLuhn)
        XCTAssertTrue("6011695471516402".isValidLuhn)

        // MasterCard
        XCTAssertTrue("5280802886982742".isValidLuhn)
        XCTAssertTrue("5410239186890221".isValidLuhn)
        XCTAssertTrue("2720992286723005".isValidLuhn)

    }

    func testDecodedJWTToken() {
        let token = try! DecodedJWTToken.createMock()
        let string = try! token.toString()

        let parsedToken = string.decodedJWTToken!

        XCTAssertEqual(parsedToken.accessToken, "access-token")
        XCTAssertEqual(parsedToken.intent, "checkout")
        XCTAssertEqual(parsedToken.coreUrl, "https://primer.io/core")
        XCTAssertEqual(parsedToken.pciUrl, "https://primer.io/pci")
        XCTAssertEqual(parsedToken.redirectUrl, "https://primer.io/redirect")
        XCTAssertEqual(parsedToken.statusUrl, "https://primer.io/status")
        XCTAssertEqual(parsedToken.configurationUrl, "https://primer.io/config")
    }

    func testSeparateEveryWith() {
        let string1 = "abcd"
        XCTAssertEqual(string1.separate(every: 1, with: "---"), "a---b---c---d")

        let string2 = "1111222233334444"
        XCTAssertEqual(string2.separate(every: 4, with: " "), "1111 2222 3333 4444")

        let string3 = "a"
        XCTAssertEqual(string3.separate(every: 1, with: "#"), "a")
    }

    func testIsValidPhoneNumberForPaymentType() {
        // Generic case
        XCTAssertTrue("+447890123456".isValidPhoneNumberForPaymentMethodType(.paymentCard))
        XCTAssertTrue("+447890123456".isValidPhoneNumberForPaymentMethodType(.adyenDotPay))
        XCTAssertTrue("+447890123456".isValidPhoneNumberForPaymentMethodType(.applePay))
        XCTAssertTrue("+447890123456".isValidPhoneNumberForPaymentMethodType(.googlePay))
        XCTAssertTrue("+129876543210".isValidPhoneNumberForPaymentMethodType(.googlePay))
        XCTAssertFalse("+12987654".isValidPhoneNumberForPaymentMethodType(.googlePay))
        XCTAssertFalse("+12987654301010101".isValidPhoneNumberForPaymentMethodType(.googlePay))

        // XenditOvo (special case)
        XCTAssertTrue("+62812345678".isValidPhoneNumberForPaymentMethodType(.xenditOvo))
        XCTAssertTrue("+628123456789".isValidPhoneNumberForPaymentMethodType(.xenditOvo))
        XCTAssertTrue("+6281234567890".isValidPhoneNumberForPaymentMethodType(.xenditOvo))
        XCTAssertFalse("+62812345678901".isValidPhoneNumberForPaymentMethodType(.xenditOvo))
        XCTAssertFalse("+6281234567".isValidPhoneNumberForPaymentMethodType(.xenditOvo))
        XCTAssertFalse("+5281234567890".isValidPhoneNumberForPaymentMethodType(.xenditOvo))
    }

    func testIsValidExpiryDateString() {
        XCTAssertThrowsError(try "".validateExpiryDateString())
        XCTAssertThrowsError(try "01/2022".validateExpiryDateString())
        XCTAssertThrowsError(try "08/2022".validateExpiryDateString())
        XCTAssertThrowsError(try "2022/2023".validateExpiryDateString())
        XCTAssertNoThrow(try almostOneYearAgoDateString().validateExpiryDateString())
        XCTAssertNoThrow(try "01/2028".validateExpiryDateString())
        XCTAssertNoThrow(try "02/2028".validateExpiryDateString())
        XCTAssertNoThrow(try "12/2028".validateExpiryDateString())
        XCTAssertNoThrow(try "01/2030".validateExpiryDateString())
    }

    func testBase64RFC4648Format() {
        XCTAssertEqual("++//==".base64RFC4648Format, "--__")
        XCTAssertEqual(
            "aHR0cHM6Ly93d3cuZ29vZ2xlLmNvbS9tYXBzL3BsYWNlL0NpdHkrb2YrUGF3bmVlL0AzOC41ODc3NjQzLC05NC43MTc2NzUzLDZ6L2RhdGE9ITRtMTAhMW0yITJtMSExc3Bhd25lZSwraW5kaWFuYSEzbTYhMXMweDg3YjExZWNmYjRlZmZmZmY6MHgyNjEzNTIzNWY3YzA2ZTkyIThtMiEzZDM2LjMzNzY3ODghNGQtOTYuODA0NDk3NSExNXNDZzl3WVhkdVpXVXNJR2x1WkdsaGJtR1NBUVJ3WVhKcjRBRUEhMTZzJTJGZyUyRjExZ2hyMTEyaG4/ZW50cnk9dHR1YQ==".base64RFC4648Format,
            "aHR0cHM6Ly93d3cuZ29vZ2xlLmNvbS9tYXBzL3BsYWNlL0NpdHkrb2YrUGF3bmVlL0AzOC41ODc3NjQzLC05NC43MTc2NzUzLDZ6L2RhdGE9ITRtMTAhMW0yITJtMSExc3Bhd25lZSwraW5kaWFuYSEzbTYhMXMweDg3YjExZWNmYjRlZmZmZmY6MHgyNjEzNTIzNWY3YzA2ZTkyIThtMiEzZDM2LjMzNzY3ODghNGQtOTYuODA0NDk3NSExNXNDZzl3WVhkdVpXVXNJR2x1WkdsaGJtR1NBUVJ3WVhKcjRBRUEhMTZzJTJGZyUyRjExZ2hyMTEyaG4_ZW50cnk9dHR1YQ"
        )
    }

    func testCompareWithVersion() {
        XCTAssertEqual("0.0.1".compareWithVersion("0.0.2"), .orderedAscending)
        XCTAssertEqual("0.0.2".compareWithVersion("0.0.3"), .orderedAscending)
        XCTAssertEqual("0.5.0".compareWithVersion("0.6.0"), .orderedAscending)
        XCTAssertEqual("0.3.2".compareWithVersion("0.5.2"), .orderedAscending)
        XCTAssertEqual("12.0.0".compareWithVersion("15.1.3"), .orderedAscending)

        XCTAssertEqual("0.0.3".compareWithVersion("0.0.2"), .orderedDescending)
        XCTAssertEqual("0.0.2".compareWithVersion("0.0.1"), .orderedDescending)
        XCTAssertEqual("0.5.0".compareWithVersion("0.4.0"), .orderedDescending)
        XCTAssertEqual("0.5.2".compareWithVersion("0.4.2"), .orderedDescending)
        XCTAssertEqual("15.0.0".compareWithVersion("12.1.3"), .orderedDescending)

        XCTAssertEqual("1.2.3".compareWithVersion("1.2.3"), .orderedSame)

        XCTAssertEqual("1.2.3".compareWithVersion("1.2"), .orderedDescending)
        XCTAssertEqual("1.2".compareWithVersion("1.2.0"), .orderedSame)
    }

    func testIsValidMobilePhoneNumber() {
        XCTAssertTrue("01234567890".isValidMobilePhoneNumber)
        XCTAssertTrue("09876543210".isValidMobilePhoneNumber)
        XCTAssertTrue("77777777777777".isValidMobilePhoneNumber)
        XCTAssertFalse("".isValidMobilePhoneNumber)
        XCTAssertFalse("abcdefghij".isValidMobilePhoneNumber)
        XCTAssertFalse("7777777777777777777".isValidMobilePhoneNumber)
        XCTAssertFalse("55555".isValidMobilePhoneNumber)
    }

    func testIsValidOTP() {
        XCTAssertTrue("123456".isValidOTP)
        XCTAssertTrue("000000".isValidOTP)
        XCTAssertTrue("750337".isValidOTP)
        XCTAssertFalse("12345".isValidOTP)
        XCTAssertFalse("1234567".isValidOTP)
        XCTAssertFalse("".isValidOTP)
    }

    

    // MARK: Helpers

    private func almostOneYearAgoDateString(format: String = "MM/YY") -> String {
        let date = Date() - 364
        let df = DateFormatter()
        df.dateFormat = "MM/YYYY"
        return df.string(from: date)
    }
}
