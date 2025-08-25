//
//  JPY_CurrencyFormattingTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

class JPY_CurrencyFormattingTests: XCTestCase {
    let zeroAmount: Int = 0
    let smallAmount: Int = 100
    let normalAmount: Int = 2560
    let bigAmount: Int = 1024955
    let hugeAmount: Int = 999999999997

    let sut = Currency(code: "JPY", decimalDigits: 0)

    func test_zero_jpy_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٠JP¥", // Arabic (Saudi Arabia)
            "da_DK": "0JP¥", // Danish (Denmark)
            "de_DE": "0JP¥", // German (Germany)
            "en_GB": "JP¥0", // English (United Kingdom)
            "en_US": "JP¥0", // English (United States)
            "es_ES": "0JP¥", // Spanish (Spain)
            "fi_FI": "0JP¥", // Finnish (Finland)
            "fr_BE": "0JP¥", // French (Belgium)
            "fr_CA": "0JP¥", // French (Canada)
            "fr_FR": "0JP¥", // French (France)
            "hi_IN": "JP¥0", // Hindi (India)
            "it_IT": "0JP¥", // Italian (Italy)
            "ja_JP": "JP¥0", // Japanese (Japan)
            "ko_KR": "JP¥0", // Korean (South Korea)
            "nl_NL": "JP¥0", // Dutch (Netherlands)
            "no_NO": "0JP¥", // Norwegian (Norway)
            "pl_PL": "0JP¥", // Polish (Poland)
            "pt_BR": "JP¥0", // Portuguese (Brazil)
            "pt_PT": "0JP¥", // Portuguese (Portugal)
            "ru_RU": "0JP¥", // Russian (Russia)
            "sv_SE": "0JP¥", // Swedish (Sweden)
            "tr_TR": "JP¥0", // Turkish (Turkey)
            "zh_CN": "JP¥0" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let zeroFormattedAmount = zeroAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(zeroFormattedAmount, expected, "Formatted amount [\(zeroFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_small_jpy_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}١٠٠JP¥", // Arabic (Saudi Arabia)
            "da_DK": "100JP¥", // Danish (Denmark)
            "de_DE": "100JP¥", // German (Germany)
            "en_GB": "JP¥100", // English (United Kingdom)
            "en_US": "JP¥100", // English (United States)
            "es_ES": "100JP¥", // Spanish (Spain)
            "fi_FI": "100JP¥", // Finnish (Finland)
            "fr_BE": "100JP¥", // French (Belgium)
            "fr_CA": "100JP¥", // French (Canada)
            "fr_FR": "100JP¥", // French (France)
            "hi_IN": "JP¥100", // Hindi (India)
            "it_IT": "100JP¥", // Italian (Italy)
            "ja_JP": "JP¥100", // Japanese (Japan)
            "ko_KR": "JP¥100", // Korean (South Korea)
            "nl_NL": "JP¥100", // Dutch (Netherlands)
            "no_NO": "100JP¥", // Norwegian (Norway)
            "pl_PL": "100JP¥", // Polish (Poland)
            "pt_BR": "JP¥100", // Portuguese (Brazil)
            "pt_PT": "100JP¥", // Portuguese (Portugal)
            "ru_RU": "100JP¥", // Russian (Russia)
            "sv_SE": "100JP¥", // Swedish (Sweden)
            "tr_TR": "JP¥100", // Turkish (Turkey)
            "zh_CN": "JP¥100" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let smallFormattedAmount = smallAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(smallFormattedAmount, expected, "Formatted amount [\(smallFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_normal_jpy_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٢٬٥٦٠JP¥", // Arabic (Saudi Arabia)
            "da_DK": "2.560JP¥", // Danish (Denmark)
            "de_DE": "2.560JP¥", // German (Germany)
            "en_GB": "JP¥2,560", // English (United Kingdom)
            "en_US": "JP¥2,560", // English (United States)
            "es_ES": "2560JP¥", // Spanish (Spain)
            "fi_FI": "2 560JP¥", // Finnish (Finland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_BE": "2 560JP¥", // French (Belgium) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "fr_CA": "2 560JP¥", // French (Canada) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_FR": "2 560JP¥", // French (France) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "hi_IN": "JP¥2,560", // Hindi (India)
            "it_IT": "2560JP¥", // Italian (Italy)
            "ja_JP": "JP¥2,560", // Japanese (Japan)
            "ko_KR": "JP¥2,560", // Korean (South Korea)
            "nl_NL": "JP¥2.560", // Dutch (Netherlands)
            "no_NO": "2 560JP¥", // Norwegian (Norway)
            "pl_PL": "2560JP¥", // Polish (Poland)
            "pt_BR": "JP¥2.560", // Portuguese (Brazil)
            "pt_PT": "2560JP¥", // Portuguese (Portugal)
            "ru_RU": "2 560JP¥", // Russian (Russia)
            "sv_SE": "2 560JP¥", // Swedish (Sweden)
            "tr_TR": "JP¥2.560", // Turkish (Turkey)
            "zh_CN": "JP¥2,560" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let normalFormattedAmount = normalAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(normalFormattedAmount, expected, "Formatted amount [\(normalFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_big_jpy_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}١٬٠٢٤٬٩٥٥JP¥", // Arabic (Saudi Arabia)
            "da_DK": "1.024.955JP¥", // Danish (Denmark)
            "de_DE": "1.024.955JP¥", // German (Germany)
            "en_GB": "JP¥1,024,955", // English (United Kingdom)
            "en_US": "JP¥1,024,955", // English (United States)
            "es_ES": "1.024.955JP¥", // Spanish (Spain)
            "fi_FI": "1 024 955JP¥", // Finnish (Finland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_BE": "1 024 955JP¥", // French (Belgium) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "fr_CA": "1 024 955JP¥", // French (Canada) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_FR": "1 024 955JP¥", // French (France) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "hi_IN": "JP¥10,24,955", // Hindi (India)
            "it_IT": "1.024.955JP¥", // Italian (Italy)
            "ja_JP": "JP¥1,024,955", // Japanese (Japan)
            "ko_KR": "JP¥1,024,955", // Korean (South Korea)
            "nl_NL": "JP¥1.024.955", // Dutch (Netherlands)
            "no_NO": "1 024 955JP¥", // Norwegian (Norway) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pl_PL": "1 024 955JP¥", // Polish (Poland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pt_BR": "JP¥1.024.955", // Portuguese (Brazil)
            "pt_PT": "1 024 955JP¥", // Portuguese (Portugal) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "ru_RU": "1 024 955JP¥", // Russian (Russia) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "sv_SE": "1 024 955JP¥", // Swedish (Sweden) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "tr_TR": "JP¥1.024.955", // Turkish (Turkey)
            "zh_CN": "JP¥1,024,955" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let bigFormattedAmount = bigAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(bigFormattedAmount, expected, "Formatted amount [\(bigFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_huge_jpy_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٩٩٩٬٩٩٩٬٩٩٩٬٩٩٧JP¥", // Arabic (Saudi Arabia)
            "da_DK": "999.999.999.997JP¥", // Danish (Denmark)
            "de_DE": "999.999.999.997JP¥", // German (Germany)
            "en_GB": "JP¥999,999,999,997", // English (United Kingdom)
            "en_US": "JP¥999,999,999,997", // English (United States)
            "es_ES": "999.999.999.997JP¥", // Spanish (Spain)
            "fi_FI": "999 999 999 997JP¥", // Finnish (Finland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_BE": "999 999 999 997JP¥", // French (Belgium) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "fr_CA": "999 999 999 997JP¥", // French (Canada) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_FR": "999 999 999 997JP¥", // French (France) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "hi_IN": "JP¥9,99,99,99,99,997", // Hindi (India)
            "it_IT": "999.999.999.997JP¥", // Italian (Italy)
            "ja_JP": "JP¥999,999,999,997", // Japanese (Japan)
            "ko_KR": "JP¥999,999,999,997", // Korean (South Korea)
            "nl_NL": "JP¥999.999.999.997", // Dutch (Netherlands)
            "no_NO": "999 999 999 997JP¥", // Norwegian (Norway) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pl_PL": "999 999 999 997JP¥", // Polish (Poland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pt_BR": "JP¥999.999.999.997", // Portuguese (Brazil)
            "pt_PT": "999 999 999 997JP¥", // Portuguese (Portugal) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "ru_RU": "999 999 999 997JP¥", // Russian (Russia) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "sv_SE": "999 999 999 997JP¥", // Swedish (Sweden) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "tr_TR": "JP¥999.999.999.997", // Turkish (Turkey)
            "zh_CN": "JP¥999,999,999,997" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let hugeFormattedAmount = hugeAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(hugeFormattedAmount, expected, "Formatted amount [\(hugeFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }
}
