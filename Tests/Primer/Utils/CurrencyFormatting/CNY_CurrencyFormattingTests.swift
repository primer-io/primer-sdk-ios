//
//  CNY_CurrencyFormattingTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

class CNY_CurrencyFormattingTests: XCTestCase {
    let zeroAmount: Int = 0
    let smallAmount: Int = 100
    let normalAmount: Int = 2560
    let bigAmount: Int = 1024955
    let hugeAmount: Int = 999999999997

    let sut = Currency(code: "CNY", decimalDigits: 2)

    func test_zero_cny_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٠٫٠٠CN¥", // Arabic (Saudi Arabia)
            "da_DK": "0,00CN¥", // Danish (Denmark)
            "de_DE": "0,00CN¥", // German (Germany)
            "en_GB": "CN¥0.00", // English (United Kingdom)
            "en_US": "CN¥0.00", // English (United States)
            "es_ES": "0,00CN¥", // Spanish (Spain)
            "fi_FI": "0,00CN¥", // Finnish (Finland)
            "fr_BE": "0,00CN¥", // French (Belgium)
            "fr_CA": "0,00CN¥", // French (Canada)
            "fr_FR": "0,00CN¥", // French (France)
            "hi_IN": "CN¥0.00", // Hindi (India)
            "it_IT": "0,00CN¥", // Italian (Italy)
            "ja_JP": "CN¥0.00", // Japanese (Japan)
            "ko_KR": "CN¥0.00", // Korean (South Korea)
            "nl_NL": "CN¥0,00", // Dutch (Netherlands)
            "no_NO": "0,00CN¥", // Norwegian (Norway)
            "pl_PL": "0,00CN¥", // Polish (Poland)
            "pt_BR": "CN¥0,00", // Portuguese (Brazil)
            "pt_PT": "0,00CN¥", // Portuguese (Portugal)
            "ru_RU": "0,00CN¥", // Russian (Russia)
            "sv_SE": "0,00CN¥", // Swedish (Sweden)
            "tr_TR": "CN¥0,00", // Turkish (Turkey)
            "zh_CN": "CN¥0.00" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let zeroFormattedAmount = zeroAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(zeroFormattedAmount, expected, "Formatted amount [\(zeroFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_small_cny_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}١٫٠٠CN¥", // Arabic (Saudi Arabia)
            "da_DK": "1,00CN¥", // Danish (Denmark)
            "de_DE": "1,00CN¥", // German (Germany)
            "en_GB": "CN¥1.00", // English (United Kingdom)
            "en_US": "CN¥1.00", // English (United States)
            "es_ES": "1,00CN¥", // Spanish (Spain)
            "fi_FI": "1,00CN¥", // Finnish (Finland)
            "fr_BE": "1,00CN¥", // French (Belgium)
            "fr_CA": "1,00CN¥", // French (Canada)
            "fr_FR": "1,00CN¥", // French (France)
            "hi_IN": "CN¥1.00", // Hindi (India)
            "it_IT": "1,00CN¥", // Italian (Italy)
            "ja_JP": "CN¥1.00", // Japanese (Japan)
            "ko_KR": "CN¥1.00", // Korean (South Korea)
            "nl_NL": "CN¥1,00", // Dutch (Netherlands)
            "no_NO": "1,00CN¥", // Norwegian (Norway)
            "pl_PL": "1,00CN¥", // Polish (Poland)
            "pt_BR": "CN¥1,00", // Portuguese (Brazil)
            "pt_PT": "1,00CN¥", // Portuguese (Portugal)
            "ru_RU": "1,00CN¥", // Russian (Russia)
            "sv_SE": "1,00CN¥", // Swedish (Sweden)
            "tr_TR": "CN¥1,00", // Turkish (Turkey)
            "zh_CN": "CN¥1.00" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let smallFormattedAmount = smallAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(smallFormattedAmount, expected, "Formatted amount [\(smallFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_normal_cny_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٢٥٫٦٠CN¥", // Arabic (Saudi Arabia)
            "da_DK": "25,60CN¥", // Danish (Denmark)
            "de_DE": "25,60CN¥", // German (Germany)
            "en_GB": "CN¥25.60", // English (United Kingdom)
            "en_US": "CN¥25.60", // English (United States)
            "es_ES": "25,60CN¥", // Spanish (Spain)
            "fi_FI": "25,60CN¥", // Finnish (Finland)
            "fr_BE": "25,60CN¥", // French (Belgium)
            "fr_CA": "25,60CN¥", // French (Canada)
            "fr_FR": "25,60CN¥", // French (France)
            "hi_IN": "CN¥25.60", // Hindi (India)
            "it_IT": "25,60CN¥", // Italian (Italy)
            "ja_JP": "CN¥25.60", // Japanese (Japan)
            "ko_KR": "CN¥25.60", // Korean (South Korea)
            "nl_NL": "CN¥25,60", // Dutch (Netherlands)
            "no_NO": "25,60CN¥", // Norwegian (Norway)
            "pl_PL": "25,60CN¥", // Polish (Poland)
            "pt_BR": "CN¥25,60", // Portuguese (Brazil)
            "pt_PT": "25,60CN¥", // Portuguese (Portugal)
            "ru_RU": "25,60CN¥", // Russian (Russia)
            "sv_SE": "25,60CN¥", // Swedish (Sweden)
            "tr_TR": "CN¥25,60", // Turkish (Turkey)
            "zh_CN": "CN¥25.60" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let normalFormattedAmount = normalAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(normalFormattedAmount, expected, "Formatted amount [\(normalFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_big_cny_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}١٠٬٢٤٩٫٥٥CN¥", // Arabic (Saudi Arabia)
            "da_DK": "10.249,55CN¥", // Danish (Denmark)
            "de_DE": "10.249,55CN¥", // German (Germany)
            "en_GB": "CN¥10,249.55", // English (United Kingdom)
            "en_US": "CN¥10,249.55", // English (United States)
            "es_ES": "10.249,55CN¥", // Spanish (Spain)
            "fi_FI": "10 249,55CN¥", // Finnish (Finland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_BE": "10 249,55CN¥", // French (Belgium) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "fr_CA": "10 249,55CN¥", // French (Canada) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_FR": "10 249,55CN¥", // French (France) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "hi_IN": "CN¥10,249.55", // Hindi (India)
            "it_IT": "10.249,55CN¥", // Italian (Italy)
            "ja_JP": "CN¥10,249.55", // Japanese (Japan)
            "ko_KR": "CN¥10,249.55", // Korean (South Korea)
            "nl_NL": "CN¥10.249,55", // Dutch (Netherlands)
            "no_NO": "10 249,55CN¥", // Norwegian (Norway) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pl_PL": "10 249,55CN¥", // Polish (Poland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pt_BR": "CN¥10.249,55", // Portuguese (Brazil)
            "pt_PT": "10 249,55CN¥", // Portuguese (Portugal) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "ru_RU": "10 249,55CN¥", // Russian (Russia) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "sv_SE": "10 249,55CN¥", // Swedish (Sweden) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "tr_TR": "CN¥10.249,55", // Turkish (Turkey)
            "zh_CN": "CN¥10,249.55" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let bigFormattedAmount = bigAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(bigFormattedAmount, expected, "Formatted amount [\(bigFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_huge_cny_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٩٬٩٩٩٬٩٩٩٬٩٩٩٫٩٧CN¥", // Arabic (Saudi Arabia)
            "da_DK": "9.999.999.999,97CN¥", // Danish (Denmark)
            "de_DE": "9.999.999.999,97CN¥", // German (Germany)
            "en_GB": "CN¥9,999,999,999.97", // English (United Kingdom)
            "en_US": "CN¥9,999,999,999.97", // English (United States)
            "es_ES": "9.999.999.999,97CN¥", // Spanish (Spain)
            "fi_FI": "9 999 999 999,97CN¥", // Finnish (Finland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_BE": "9 999 999 999,97CN¥", // French (Belgium) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "fr_CA": "9 999 999 999,97CN¥", // French (Canada) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_FR": "9 999 999 999,97CN¥", // French (France) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "hi_IN": "CN¥9,99,99,99,999.97", // Hindi (India)
            "it_IT": "9.999.999.999,97CN¥", // Italian (Italy)
            "ja_JP": "CN¥9,999,999,999.97", // Japanese (Japan)
            "ko_KR": "CN¥9,999,999,999.97", // Korean (South Korea)
            "nl_NL": "CN¥9.999.999.999,97", // Dutch (Netherlands)
            "no_NO": "9 999 999 999,97CN¥", // Norwegian (Norway) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pl_PL": "9 999 999 999,97CN¥", // Polish (Poland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pt_BR": "CN¥9.999.999.999,97", // Portuguese (Brazil)
            "pt_PT": "9 999 999 999,97CN¥", // Portuguese (Portugal) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "ru_RU": "9 999 999 999,97CN¥", // Russian (Russia) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "sv_SE": "9 999 999 999,97CN¥", // Swedish (Sweden) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "tr_TR": "CN¥9.999.999.999,97", // Turkish (Turkey)
            "zh_CN": "CN¥9,999,999,999.97" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let hugeFormattedAmount = hugeAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(hugeFormattedAmount, expected, "Formatted amount [\(hugeFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }
}
