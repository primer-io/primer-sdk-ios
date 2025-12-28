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
        Constants.testCardNumbers.flatMap(\.value).forEach {
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
//        XCTAssertThrowsError(try "".validateExpiryDateString())
//        XCTAssertThrowsError(try "01/2022".validateExpiryDateString())
//        XCTAssertThrowsError(try "08/2022".validateExpiryDateString())
//        XCTAssertThrowsError(try "2022/2023".validateExpiryDateString())

        // DEBUG: Log values to understand CI failure
        let now = Date()
        let almostOneYearAgo = Date() - (60 * 60 * 24 * 364)
        let dateString = almostOneYearAgoDateString()
        let timezone = TimeZone.current.identifier
        let offset = TimeZone.current.secondsFromGMT() / 3600

        // This message will show in CI if the test fails
        let debugInfo = """
            Generated: '\(dateString)' | \
            Now: \(now) | \
            364 days ago: \(almostOneYearAgo) | \
            TZ: \(timezone) (UTC\(offset >= 0 ? "+" : "")\(offset))
            """

        XCTAssertThrowsError(
            try almostOneYearAgoDateString().validateExpiryDateString(),
            debugInfo
        )
//        XCTAssertNoThrow(try "01/2028".validateExpiryDateString())
//        XCTAssertNoThrow(try "02/2028".validateExpiryDateString())
//        XCTAssertNoThrow(try "12/2028".validateExpiryDateString())
//        XCTAssertNoThrow(try "01/2030".validateExpiryDateString())
//        
//        // Test MM/YY format support
//        XCTAssertNoThrow(try "01/28".validateExpiryDateString())
//        XCTAssertNoThrow(try "02/28".validateExpiryDateString())
//        XCTAssertNoThrow(try "12/28".validateExpiryDateString())
//        XCTAssertNoThrow(try "01/30".validateExpiryDateString())
//        XCTAssertThrowsError(try "01/22".validateExpiryDateString()) // Past date
//        XCTAssertThrowsError(try "08/22".validateExpiryDateString()) // Past date
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

    // MARK: - NSRange Text Processing Tests

    func testRangeFromNSRange() {
        let testString = "Hello, World!"

        // Valid ranges
        let range1 = NSRange(location: 0, length: 5)
        XCTAssertNotNil(testString.range(from: range1))

        let range2 = NSRange(location: 7, length: 5)
        XCTAssertNotNil(testString.range(from: range2))

        let range3 = NSRange(location: 0, length: testString.count)
        XCTAssertNotNil(testString.range(from: range3))

        // Invalid ranges
        let invalidRange1 = NSRange(location: 100, length: 5)
        XCTAssertNil(testString.range(from: invalidRange1))

        let invalidRange2 = NSRange(location: 0, length: 100)
        XCTAssertNil(testString.range(from: invalidRange2))

        // Empty string
        let emptyString = ""
        let emptyRange = NSRange(location: 0, length: 0)
        XCTAssertNotNil(emptyString.range(from: emptyRange))

        // Test with emoji
        let emojiString = "Hello 👋 World 🌍"
        let emojiRange = NSRange(location: 0, length: 7)
        XCTAssertNotNil(emojiString.range(from: emojiRange))
    }

    func testReplacingCharactersInNSRange() {
        // Basic replacement
        let string1 = "Hello, World!"
        let range1 = NSRange(location: 0, length: 5)
        XCTAssertEqual(string1.replacingCharacters(in: range1, with: "Hi"), "Hi, World!")

        // Replace in middle
        let string2 = "Hello, World!"
        let range2 = NSRange(location: 7, length: 5)
        XCTAssertEqual(string2.replacingCharacters(in: range2, with: "Swift"), "Hello, Swift!")

        // Delete (replace with empty string)
        let string3 = "Hello, World!"
        let range3 = NSRange(location: 5, length: 2)
        XCTAssertEqual(string3.replacingCharacters(in: range3, with: ""), "HelloWorld!")

        // Insert (zero-length range)
        let string4 = "Hello World!"
        let range4 = NSRange(location: 5, length: 0)
        XCTAssertEqual(string4.replacingCharacters(in: range4, with: ","), "Hello, World!")

        // Invalid range (should return original string)
        let string5 = "Hello, World!"
        let invalidRange = NSRange(location: 100, length: 5)
        XCTAssertEqual(string5.replacingCharacters(in: invalidRange, with: "Test"), "Hello, World!")

        // Empty string
        let emptyString = ""
        let emptyRange = NSRange(location: 0, length: 0)
        XCTAssertEqual(emptyString.replacingCharacters(in: emptyRange, with: "Hello"), "Hello")

        // Expiry date scenario (MM/YY)
        let expiryDate = "12/25"
        let deleteRange = NSRange(location: 3, length: 1)
        XCTAssertEqual(expiryDate.replacingCharacters(in: deleteRange, with: ""), "12/5")

        // Card number scenario
        let cardNumber = "4111 1111 1111 1111"
        let cardRange = NSRange(location: 0, length: 4)
        XCTAssertEqual(cardNumber.replacingCharacters(in: cardRange, with: "5555"), "5555 1111 1111 1111")

        // Test with emoji (NSRange length: 7 covers "Hello " but not the emoji which takes 2 UTF-16 units)
        let emojiString = "Hello 👋"
        let emojiRange = NSRange(location: 0, length: 7)
        XCTAssertEqual(emojiString.replacingCharacters(in: emojiRange, with: "Hi"), "Hi👋")
    }

    func testUnformattedPosition() {
        // Card number with spaces
        let cardNumber = "4111 2222 3333 4444"
        XCTAssertEqual(cardNumber.unformattedPosition(from: 0, separator: " "), 0)
        XCTAssertEqual(cardNumber.unformattedPosition(from: 4, separator: " "), 4)
        XCTAssertEqual(cardNumber.unformattedPosition(from: 5, separator: " "), 4) // After first space
        XCTAssertEqual(cardNumber.unformattedPosition(from: 9, separator: " "), 8)
        XCTAssertEqual(cardNumber.unformattedPosition(from: 10, separator: " "), 8) // After second space
        XCTAssertEqual(cardNumber.unformattedPosition(from: 19, separator: " "), 16) // End

        // Expiry date with slash
        let expiryDate = "12/25"
        XCTAssertEqual(expiryDate.unformattedPosition(from: 0, separator: "/"), 0)
        XCTAssertEqual(expiryDate.unformattedPosition(from: 2, separator: "/"), 2)
        XCTAssertEqual(expiryDate.unformattedPosition(from: 3, separator: "/"), 2) // After slash
        XCTAssertEqual(expiryDate.unformattedPosition(from: 4, separator: "/"), 3)
        XCTAssertEqual(expiryDate.unformattedPosition(from: 5, separator: "/"), 4)

        // String without separator
        let noSeparator = "1234567890"
        XCTAssertEqual(noSeparator.unformattedPosition(from: 0, separator: " "), 0)
        XCTAssertEqual(noSeparator.unformattedPosition(from: 5, separator: " "), 5)
        XCTAssertEqual(noSeparator.unformattedPosition(from: 10, separator: " "), 10)

        // Empty string
        let emptyString = ""
        XCTAssertEqual(emptyString.unformattedPosition(from: 0, separator: " "), 0)

        // Position beyond string length
        let shortString = "123"
        XCTAssertEqual(shortString.unformattedPosition(from: 100, separator: " "), 3)

        // Multiple consecutive separators
        let multipleSeparators = "12  34"
        XCTAssertEqual(multipleSeparators.unformattedPosition(from: 0, separator: " "), 0)
        XCTAssertEqual(multipleSeparators.unformattedPosition(from: 2, separator: " "), 2)
        XCTAssertEqual(multipleSeparators.unformattedPosition(from: 3, separator: " "), 2) // After first space
        XCTAssertEqual(multipleSeparators.unformattedPosition(from: 4, separator: " "), 2) // After second space
        XCTAssertEqual(multipleSeparators.unformattedPosition(from: 5, separator: " "), 3)
        XCTAssertEqual(multipleSeparators.unformattedPosition(from: 6, separator: " "), 4)
    }

    // MARK: Helpers

    private func almostOneYearAgoDateString(format: String = "MM/YY") -> String {
        let date = Date() - (60 * 60 * 24 * 364)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/YYYY"
        return dateFormatter.string(from: date)
    }
}
