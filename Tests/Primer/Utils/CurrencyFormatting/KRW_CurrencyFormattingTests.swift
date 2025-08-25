//
//  KRW_CurrencyFormattingTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

class KRW_CurrencyFormattingTests: XCTestCase {
    let zeroAmount: Int = 0
    let smallAmount: Int = 100
    let normalAmount: Int = 2560
    let bigAmount: Int = 1024955
    let hugeAmount: Int = 999999999997

    let sut = Currency(code: "KRW", decimalDigits: 0)

    func test_zero_krw_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٠₩", // Arabic (Saudi Arabia)
            "da_DK": "0₩", // Danish (Denmark)
            "de_DE": "0₩", // German (Germany)
            "en_GB": "₩0", // English (United Kingdom)
            "en_US": "₩0", // English (United States)
            "es_ES": "0₩", // Spanish (Spain)
            "fi_FI": "0₩", // Finnish (Finland)
            "fr_BE": "0₩", // French (Belgium)
            "fr_CA": "0₩", // French (Canada)
            "fr_FR": "0₩", // French (France)
            "hi_IN": "₩0", // Hindi (India)
            "it_IT": "0₩", // Italian (Italy)
            "ja_JP": "₩0", // Japanese (Japan)
            "ko_KR": "₩0", // Korean (South Korea)
            "nl_NL": "₩0", // Dutch (Netherlands)
            "no_NO": "0₩", // Norwegian (Norway)
            "pl_PL": "0₩", // Polish (Poland)
            "pt_BR": "₩0", // Portuguese (Brazil)
            "pt_PT": "0₩", // Portuguese (Portugal)
            "ru_RU": "0₩", // Russian (Russia)
            "sv_SE": "0₩", // Swedish (Sweden)
            "tr_TR": "₩0", // Turkish (Turkey)
            "zh_CN": "₩0" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let zeroFormattedAmount = zeroAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(zeroFormattedAmount, expected, "Formatted amount [\(zeroFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_small_krw_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}١٠٠₩", // Arabic (Saudi Arabia)
            "da_DK": "100₩", // Danish (Denmark)
            "de_DE": "100₩", // German (Germany)
            "en_GB": "₩100", // English (United Kingdom)
            "en_US": "₩100", // English (United States)
            "es_ES": "100₩", // Spanish (Spain)
            "fi_FI": "100₩", // Finnish (Finland)
            "fr_BE": "100₩", // French (Belgium)
            "fr_CA": "100₩", // French (Canada)
            "fr_FR": "100₩", // French (France)
            "hi_IN": "₩100", // Hindi (India)
            "it_IT": "100₩", // Italian (Italy)
            "ja_JP": "₩100", // Japanese (Japan)
            "ko_KR": "₩100", // Korean (South Korea)
            "nl_NL": "₩100", // Dutch (Netherlands)
            "no_NO": "100₩", // Norwegian (Norway)
            "pl_PL": "100₩", // Polish (Poland)
            "pt_BR": "₩100", // Portuguese (Brazil)
            "pt_PT": "100₩", // Portuguese (Portugal)
            "ru_RU": "100₩", // Russian (Russia)
            "sv_SE": "100₩", // Swedish (Sweden)
            "tr_TR": "₩100", // Turkish (Turkey)
            "zh_CN": "₩100" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let smallFormattedAmount = smallAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(smallFormattedAmount, expected, "Formatted amount [\(smallFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_normal_krw_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٢٬٥٦٠₩", // Arabic (Saudi Arabia)
            "da_DK": "2.560₩", // Danish (Denmark)
            "de_DE": "2.560₩", // German (Germany)
            "en_GB": "₩2,560", // English (United Kingdom)
            "en_US": "₩2,560", // English (United States)
            "es_ES": "2560₩", // Spanish (Spain)
            "fi_FI": "2 560₩", // Finnish (Finland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_BE": "2 560₩", // French (Belgium) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "fr_CA": "2 560₩", // French (Canada) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_FR": "2 560₩", // French (France) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "hi_IN": "₩2,560", // Hindi (India)
            "it_IT": "2560₩", // Italian (Italy)
            "ja_JP": "₩2,560", // Japanese (Japan)
            "ko_KR": "₩2,560", // Korean (South Korea)
            "nl_NL": "₩2.560", // Dutch (Netherlands)
            "no_NO": "2 560₩", // Norwegian (Norway) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pl_PL": "2560₩", // Polish (Poland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pt_BR": "₩2.560", // Portuguese (Brazil)
            "pt_PT": "2560₩", // Portuguese (Portugal) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "ru_RU": "2 560₩", // Russian (Russia) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "sv_SE": "2 560₩", // Swedish (Sweden) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "tr_TR": "₩2.560", // Turkish (Turkey)
            "zh_CN": "₩2,560" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let normalFormattedAmount = normalAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(normalFormattedAmount, expected, "Formatted amount [\(normalFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_big_krw_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}١٬٠٢٤٬٩٥٥₩", // Arabic (Saudi Arabia)
            "da_DK": "1.024.955₩", // Danish (Denmark)
            "de_DE": "1.024.955₩", // German (Germany)
            "en_GB": "₩1,024,955", // English (United Kingdom)
            "en_US": "₩1,024,955", // English (United States)
            "es_ES": "1.024.955₩", // Spanish (Spain)
            "fi_FI": "1 024 955₩", // Finnish (Finland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_BE": "1 024 955₩", // French (Belgium) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "fr_CA": "1 024 955₩", // French (Canada) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_FR": "1 024 955₩", // French (France) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "hi_IN": "₩10,24,955", // Hindi (India)
            "it_IT": "1.024.955₩", // Italian (Italy)
            "ja_JP": "₩1,024,955", // Japanese (Japan)
            "ko_KR": "₩1,024,955", // Korean (South Korea)
            "nl_NL": "₩1.024.955", // Dutch (Netherlands)
            "no_NO": "1 024 955₩", // Norwegian (Norway) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pl_PL": "1 024 955₩", // Polish (Poland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pt_BR": "₩1.024.955", // Portuguese (Brazil)
            "pt_PT": "1 024 955₩", // Portuguese (Portugal) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "ru_RU": "1 024 955₩", // Russian (Russia) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "sv_SE": "1 024 955₩", // Swedish (Sweden) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "tr_TR": "₩1.024.955", // Turkish (Turkey)
            "zh_CN": "₩1,024,955" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let bigFormattedAmount = bigAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(bigFormattedAmount, expected, "Formatted amount [\(bigFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_huge_krw_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٩٩٩٬٩٩٩٬٩٩٩٬٩٩٧₩", // Arabic (Saudi Arabia)
            "da_DK": "999.999.999.997₩", // Danish (Denmark)
            "de_DE": "999.999.999.997₩", // German (Germany)
            "en_GB": "₩999,999,999,997", // English (United Kingdom)
            "en_US": "₩999,999,999,997", // English (United States)
            "es_ES": "999.999.999.997₩", // Spanish (Spain)
            "fi_FI": "999 999 999 997₩", // Finnish (Finland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_BE": "999 999 999 997₩", // French (Belgium) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "fr_CA": "999 999 999 997₩", // French (Canada) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_FR": "999 999 999 997₩", // French (France) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "hi_IN": "₩9,99,99,99,99,997", // Hindi (India)
            "it_IT": "999.999.999.997₩", // Italian (Italy)
            "ja_JP": "₩999,999,999,997", // Japanese (Japan)
            "ko_KR": "₩999,999,999,997", // Korean (South Korea)
            "nl_NL": "₩999.999.999.997", // Dutch (Netherlands)
            "no_NO": "999 999 999 997₩", // Norwegian (Norway) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pl_PL": "999 999 999 997₩", // Polish (Poland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pt_BR": "₩999.999.999.997", // Portuguese (Brazil)
            "pt_PT": "999 999 999 997₩", // Portuguese (Portugal) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "ru_RU": "999 999 999 997₩", // Russian (Russia) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "sv_SE": "999 999 999 997₩", // Swedish (Sweden) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "tr_TR": "₩999.999.999.997", // Turkish (Turkey)
            "zh_CN": "₩999,999,999,997" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let hugeFormattedAmount = hugeAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(hugeFormattedAmount, expected, "Formatted amount [\(hugeFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }
}
