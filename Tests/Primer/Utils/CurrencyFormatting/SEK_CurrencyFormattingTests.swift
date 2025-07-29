//
//  SEK_CurrencyFormattingTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

class SEK_CurrencyFormattingTests: XCTestCase {
    let zeroAmount: Int = 0
    let smallAmount: Int = 100
    let normalAmount: Int = 2560
    let bigAmount: Int = 1024955
    let hugeAmount: Int = 999999999997

    let sut = Currency(code: "SEK", decimalDigits: 2)

    func test_zero_sek_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٠٫٠٠SEK", // Arabic (Saudi Arabia)
            "da_DK": "0,00SEK", // Danish (Denmark)
            "de_DE": "0,00SEK", // German (Germany)
            "en_GB": "SEK0.00", // English (United Kingdom)
            "en_US": "SEK0.00", // English (United States)
            "es_ES": "0,00SEK", // Spanish (Spain)
            "fi_FI": "0,00SEK", // Finnish (Finland)
            "fr_BE": "0,00SEK", // French (Belgium)
            "fr_CA": "0,00SEK", // French (Canada)
            "fr_FR": "0,00SEK", // French (France)
            "hi_IN": "SEK0.00", // Hindi (India)
            "it_IT": "0,00SEK", // Italian (Italy)
            "ja_JP": "SEK0.00", // Japanese (Japan)
            "ko_KR": "SEK0.00", // Korean (South Korea)
            "nl_NL": "SEK0,00", // Dutch (Netherlands)
            "no_NO": "0,00SEK", // Norwegian (Norway)
            "pl_PL": "0,00SEK", // Polish (Poland)
            "pt_BR": "SEK0,00", // Portuguese (Brazil)
            "pt_PT": "0,00SEK", // Portuguese (Portugal)
            "ru_RU": "0,00SEK", // Russian (Russia)
            "sv_SE": "0,00SEK", // Swedish (Sweden)
            "tr_TR": "SEK0,00", // Turkish (Turkey)
            "zh_CN": "SEK0.00" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let zeroFormattedAmount = zeroAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(zeroFormattedAmount, expected, "Formatted amount [\(zeroFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_small_sek_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}١٫٠٠SEK", // Arabic (Saudi Arabia)
            "da_DK": "1,00SEK", // Danish (Denmark)
            "de_DE": "1,00SEK", // German (Germany)
            "en_GB": "SEK1.00", // English (United Kingdom)
            "en_US": "SEK1.00", // English (United States)
            "es_ES": "1,00SEK", // Spanish (Spain)
            "fi_FI": "1,00SEK", // Finnish (Finland)
            "fr_BE": "1,00SEK", // French (Belgium)
            "fr_CA": "1,00SEK", // French (Canada)
            "fr_FR": "1,00SEK", // French (France)
            "hi_IN": "SEK1.00", // Hindi (India)
            "it_IT": "1,00SEK", // Italian (Italy)
            "ja_JP": "SEK1.00", // Japanese (Japan)
            "ko_KR": "SEK1.00", // Korean (South Korea)
            "nl_NL": "SEK1,00", // Dutch (Netherlands)
            "no_NO": "1,00SEK", // Norwegian (Norway)
            "pl_PL": "1,00SEK", // Polish (Poland)
            "pt_BR": "SEK1,00", // Portuguese (Brazil)
            "pt_PT": "1,00SEK", // Portuguese (Portugal)
            "ru_RU": "1,00SEK", // Russian (Russia)
            "sv_SE": "1,00SEK", // Swedish (Sweden)
            "tr_TR": "SEK1,00", // Turkish (Turkey)
            "zh_CN": "SEK1.00" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let smallFormattedAmount = smallAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(smallFormattedAmount, expected, "Formatted amount [\(smallFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_normal_sek_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٢٥٫٦٠SEK", // Arabic (Saudi Arabia)
            "da_DK": "25,60SEK", // Danish (Denmark)
            "de_DE": "25,60SEK", // German (Germany)
            "en_GB": "SEK25.60", // English (United Kingdom)
            "en_US": "SEK25.60", // English (United States)
            "es_ES": "25,60SEK", // Spanish (Spain)
            "fi_FI": "25,60SEK", // Finnish (Finland)
            "fr_BE": "25,60SEK", // French (Belgium)
            "fr_CA": "25,60SEK", // French (Canada)
            "fr_FR": "25,60SEK", // French (France)
            "hi_IN": "SEK25.60", // Hindi (India)
            "it_IT": "25,60SEK", // Italian (Italy)
            "ja_JP": "SEK25.60", // Japanese (Japan)
            "ko_KR": "SEK25.60", // Korean (South Korea)
            "nl_NL": "SEK25,60", // Dutch (Netherlands)
            "no_NO": "25,60SEK", // Norwegian (Norway)
            "pl_PL": "25,60SEK", // Polish (Poland)
            "pt_BR": "SEK25,60", // Portuguese (Brazil)
            "pt_PT": "25,60SEK", // Portuguese (Portugal)
            "ru_RU": "25,60SEK", // Russian (Russia)
            "sv_SE": "25,60SEK", // Swedish (Sweden)
            "tr_TR": "SEK25,60", // Turkish (Turkey)
            "zh_CN": "SEK25.60" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let normalFormattedAmount = normalAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(normalFormattedAmount, expected, "Formatted amount [\(normalFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_big_sek_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}١٠٬٢٤٩٫٥٥SEK", // Arabic (Saudi Arabia)
            "da_DK": "10.249,55SEK", // Danish (Denmark)
            "de_DE": "10.249,55SEK", // German (Germany)
            "en_GB": "SEK10,249.55", // English (United Kingdom)
            "en_US": "SEK10,249.55", // English (United States)
            "es_ES": "10.249,55SEK", // Spanish (Spain)
            "fi_FI": "10 249,55SEK", // Finnish (Finland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_BE": "10 249,55SEK", // French (Belgium) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "fr_CA": "10 249,55SEK", // French (Canada) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_FR": "10 249,55SEK", // French (France) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "hi_IN": "SEK10,249.55", // Hindi (India)
            "it_IT": "10.249,55SEK", // Italian (Italy)
            "ja_JP": "SEK10,249.55", // Japanese (Japan)
            "ko_KR": "SEK10,249.55", // Korean (South Korea)
            "nl_NL": "SEK10.249,55", // Dutch (Netherlands)
            "no_NO": "10 249,55SEK", // Norwegian (Norway) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pl_PL": "10 249,55SEK", // Polish (Poland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pt_BR": "SEK10.249,55", // Portuguese (Brazil)
            "pt_PT": "10 249,55SEK", // Portuguese (Portugal) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "ru_RU": "10 249,55SEK", // Russian (Russia) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "sv_SE": "10 249,55SEK", // Swedish (Sweden) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "tr_TR": "SEK10.249,55", // Turkish (Turkey)
            "zh_CN": "SEK10,249.55" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let bigFormattedAmount = bigAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(bigFormattedAmount, expected, "Formatted amount [\(bigFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_huge_sek_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٩٬٩٩٩٬٩٩٩٬٩٩٩٫٩٧SEK", // Arabic (Saudi Arabia)
            "da_DK": "9.999.999.999,97SEK", // Danish (Denmark)
            "de_DE": "9.999.999.999,97SEK", // German (Germany)
            "en_GB": "SEK9,999,999,999.97", // English (United Kingdom)
            "en_US": "SEK9,999,999,999.97", // English (United States)
            "es_ES": "9.999.999.999,97SEK", // Spanish (Spain)
            "fi_FI": "9 999 999 999,97SEK", // Finnish (Finland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_BE": "9 999 999 999,97SEK", // French (Belgium) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "fr_CA": "9 999 999 999,97SEK", // French (Canada) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_FR": "9 999 999 999,97SEK", // French (France) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "hi_IN": "SEK9,99,99,99,999.97", // Hindi (India)
            "it_IT": "9.999.999.999,97SEK", // Italian (Italy)
            "ja_JP": "SEK9,999,999,999.97", // Japanese (Japan)
            "ko_KR": "SEK9,999,999,999.97", // Korean (South Korea)
            "nl_NL": "SEK9.999.999.999,97", // Dutch (Netherlands)
            "no_NO": "9 999 999 999,97SEK", // Norwegian (Norway) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pl_PL": "9 999 999 999,97SEK", // Polish (Poland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pt_BR": "SEK9.999.999.999,97", // Portuguese (Brazil)
            "pt_PT": "9 999 999 999,97SEK", // Portuguese (Portugal) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "ru_RU": "9 999 999 999,97SEK", // Russian (Russia) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "sv_SE": "9 999 999 999,97SEK", // Swedish (Sweden) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "tr_TR": "SEK9.999.999.999,97", // Turkish (Turkey)
            "zh_CN": "SEK9,999,999,999.97" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let hugeFormattedAmount = hugeAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(hugeFormattedAmount, expected, "Formatted amount [\(hugeFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }
}
