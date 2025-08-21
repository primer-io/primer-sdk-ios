//
//  StringExtensionTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

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
        XCTAssertThrowsError(try almostOneYearAgoDateString().validateExpiryDateString())
        XCTAssertNoThrow(try "01/2028".validateExpiryDateString())
        XCTAssertNoThrow(try "02/2028".validateExpiryDateString())
        XCTAssertNoThrow(try "12/2028".validateExpiryDateString())
        XCTAssertNoThrow(try "01/2030".validateExpiryDateString())
        
        // Test MM/YY format support
        XCTAssertNoThrow(try "01/28".validateExpiryDateString())
        XCTAssertNoThrow(try "02/28".validateExpiryDateString())
        XCTAssertNoThrow(try "12/28".validateExpiryDateString())
        XCTAssertNoThrow(try "01/30".validateExpiryDateString())
        XCTAssertThrowsError(try "01/22".validateExpiryDateString()) // Past date
        XCTAssertThrowsError(try "08/22".validateExpiryDateString()) // Past date
        
        // Test invalid year formats (5+ digits) - ESC-620
        XCTAssertThrowsError(try "03/77777".validateExpiryDateString()) // 5 digit year
        XCTAssertThrowsError(try "07/77444".validateExpiryDateString()) // 5 digit year
        XCTAssertThrowsError(try "03/12345".validateExpiryDateString()) // 5 digit year
        XCTAssertThrowsError(try "03/123456".validateExpiryDateString()) // 6 digit year
        XCTAssertThrowsError(try "03/1234567".validateExpiryDateString()) // 7 digit year
        XCTAssertThrowsError(try "03/20301".validateExpiryDateString()) // 5 digit year
        XCTAssertThrowsError(try "03/203011".validateExpiryDateString()) // 6 digit year
        
        // Test invalid year formats (1 or 3 digits)
        XCTAssertThrowsError(try "03/7".validateExpiryDateString()) // 1 digit year
        XCTAssertThrowsError(try "03/777".validateExpiryDateString()) // 3 digit year
        XCTAssertThrowsError(try "03/234".validateExpiryDateString()) // 3 digit year
        
        // Test valid 2-digit years should work (using years that won't be in the past)
        XCTAssertNoThrow(try "03/30".validateExpiryDateString()) // Valid 2 digit year (2030)
        XCTAssertNoThrow(try "03/35".validateExpiryDateString()) // Valid 2 digit year (2035)
        
        // Test valid 4-digit years should work
        XCTAssertNoThrow(try "03/2030".validateExpiryDateString()) // Valid 4 digit year
        XCTAssertNoThrow(try "03/2035".validateExpiryDateString()) // Valid 4 digit year
        
        // Test that past years are rejected (both 2 and 4 digit formats)
        XCTAssertThrowsError(try "03/77".validateExpiryDateString()) // 77 is interpreted as 1977 (past)
        XCTAssertThrowsError(try "03/20".validateExpiryDateString()) // 20 is interpreted as 2020 (past)
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

    func testIsValidOTP() {
        XCTAssertTrue("123456".isValidOTP)
        XCTAssertTrue("000000".isValidOTP)
        XCTAssertTrue("750337".isValidOTP)
        XCTAssertFalse("12345".isValidOTP)
        XCTAssertFalse("1234567".isValidOTP)
        XCTAssertFalse("".isValidOTP)
    }

    func testNormalizedFourDigitYear() {
        // Test 2-digit year conversion (should convert to current century)
        XCTAssertEqual("30".normalizedFourDigitYear(), "2030")
        XCTAssertEqual("25".normalizedFourDigitYear(), "2025")
        XCTAssertEqual("50".normalizedFourDigitYear(), "2050")
        XCTAssertEqual("99".normalizedFourDigitYear(), "2099")
        XCTAssertEqual("00".normalizedFourDigitYear(), "2000")
        XCTAssertEqual("01".normalizedFourDigitYear(), "2001")

        // Test 4-digit year (should return as-is)
        XCTAssertEqual("2030".normalizedFourDigitYear(), "2030")
        XCTAssertEqual("2025".normalizedFourDigitYear(), "2025")
        XCTAssertEqual("1999".normalizedFourDigitYear(), "1999")
        XCTAssertEqual("2100".normalizedFourDigitYear(), "2100")
        XCTAssertEqual("0000".normalizedFourDigitYear(), "0000")

        // Test invalid inputs (should return nil)
        XCTAssertNil("".normalizedFourDigitYear())
        XCTAssertNil("1".normalizedFourDigitYear())
        XCTAssertNil("123".normalizedFourDigitYear())
        XCTAssertNil("12345".normalizedFourDigitYear())
        XCTAssertNil("abc".normalizedFourDigitYear())
        XCTAssertNil("ab".normalizedFourDigitYear())
        XCTAssertNil("abcd".normalizedFourDigitYear())
        XCTAssertNil("a1".normalizedFourDigitYear())
        XCTAssertNil("1a".normalizedFourDigitYear())
        XCTAssertNil("2a30".normalizedFourDigitYear())
        XCTAssertNil("20a0".normalizedFourDigitYear())
        XCTAssertNil(" 30".normalizedFourDigitYear())
        XCTAssertNil("30 ".normalizedFourDigitYear())
        XCTAssertNil(" 2030 ".normalizedFourDigitYear())
        XCTAssertNil("30/40".normalizedFourDigitYear())
        XCTAssertNil("-30".normalizedFourDigitYear())
        XCTAssertNil("+30".normalizedFourDigitYear())

        // Edge cases with special characters
        XCTAssertNil("\\n30".normalizedFourDigitYear())
        XCTAssertNil("30\\t".normalizedFourDigitYear())
        XCTAssertNil("3.0".normalizedFourDigitYear())
        XCTAssertNil("3,0".normalizedFourDigitYear())
    }

    // MARK: Helpers

    private func almostOneYearAgoDateString(format: String = "MM/YY") -> String {
        let date = Date() - (60 * 60 * 24 * 364)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/YYYY"
        return dateFormatter.string(from: date)
    }
}
