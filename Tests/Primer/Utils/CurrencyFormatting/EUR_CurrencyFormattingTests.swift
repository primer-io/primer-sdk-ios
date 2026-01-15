//
//  EUR_CurrencyFormattingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
@testable import PrimerSDK
import XCTest

class EUR_CurrencyFormattingTests: XCTestCase {
    let zeroAmount: Int = 0
    let smallAmount: Int = 100
    let normalAmount: Int = 2560
    let bigAmount: Int = 1024955
    let hugeAmount: Int = 999999999997

    let sut = Currency(code: "EUR", decimalDigits: 2)

    func test_zero_eur_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٠٫٠٠€", // Arabic (Saudi Arabia)
            "da_DK": "0,00€", // Danish (Denmark)
            "de_DE": "0,00€", // German (Germany)
            "en_GB": "€0.00", // English (United Kingdom)
            "en_US": "€0.00", // English (United States)
            "es_ES": "0,00€", // Spanish (Spain)
            "fi_FI": "0,00€", // Finnish (Finland)
            "fr_BE": "0,00€", // French (Belgium)
            "fr_CA": "0,00€", // French (Canada)
            "fr_FR": "0,00€", // French (France)
            "hi_IN": "€0.00", // Hindi (India)
            "it_IT": "0,00€", // Italian (Italy)
            "ja_JP": "€0.00", // Japanese (Japan)
            "ko_KR": "€0.00", // Korean (South Korea)
            "nl_NL": "€0,00", // Dutch (Netherlands)
            "no_NO": "0,00€", // Norwegian (Norway)
            "pl_PL": "0,00€", // Polish (Poland)
            "pt_BR": "€0,00", // Portuguese (Brazil)
            "pt_PT": "0,00€", // Portuguese (Portugal)
            "ru_RU": "0,00€", // Russian (Russia)
            "sv_SE": "0,00€", // Swedish (Sweden)
            "tr_TR": "€0,00", // Turkish (Turkey)
            "zh_CN": "€0.00" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let zeroFormattedAmount = zeroAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(zeroFormattedAmount, expected, "Formatted amount [\(zeroFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_small_eur_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}١٫٠٠€", // Arabic (Saudi Arabia)
            "da_DK": "1,00€", // Danish (Denmark)
            "de_DE": "1,00€", // German (Germany)
            "en_GB": "€1.00", // English (United Kingdom)
            "en_US": "€1.00", // English (United States)
            "es_ES": "1,00€", // Spanish (Spain)
            "fi_FI": "1,00€", // Finnish (Finland)
            "fr_BE": "1,00€", // French (Belgium)
            "fr_CA": "1,00€", // French (Canada)
            "fr_FR": "1,00€", // French (France)
            "hi_IN": "€1.00", // Hindi (India)
            "it_IT": "1,00€", // Italian (Italy)
            "ja_JP": "€1.00", // Japanese (Japan)
            "ko_KR": "€1.00", // Korean (South Korea)
            "nl_NL": "€1,00", // Dutch (Netherlands)
            "no_NO": "1,00€", // Norwegian (Norway)
            "pl_PL": "1,00€", // Polish (Poland)
            "pt_BR": "€1,00", // Portuguese (Brazil)
            "pt_PT": "1,00€", // Portuguese (Portugal)
            "ru_RU": "1,00€", // Russian (Russia)
            "sv_SE": "1,00€", // Swedish (Sweden)
            "tr_TR": "€1,00", // Turkish (Turkey)
            "zh_CN": "€1.00" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let smallFormattedAmount = smallAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(smallFormattedAmount, expected, "Formatted amount [\(smallFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_normal_eur_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٢٥٫٦٠€", // Arabic (Saudi Arabia)
            "da_DK": "25,60€", // Danish (Denmark)
            "de_DE": "25,60€", // German (Germany)
            "en_GB": "€25.60", // English (United Kingdom)
            "en_US": "€25.60", // English (United States)
            "es_ES": "25,60€", // Spanish (Spain)
            "fi_FI": "25,60€", // Finnish (Finland)
            "fr_BE": "25,60€", // French (Belgium)
            "fr_CA": "25,60€", // French (Canada)
            "fr_FR": "25,60€", // French (France)
            "hi_IN": "€25.60", // Hindi (India)
            "it_IT": "25,60€", // Italian (Italy)
            "ja_JP": "€25.60", // Japanese (Japan)
            "ko_KR": "€25.60", // Korean (South Korea)
            "nl_NL": "€25,60", // Dutch (Netherlands)
            "no_NO": "25,60€", // Norwegian (Norway)
            "pl_PL": "25,60€", // Polish (Poland)
            "pt_BR": "€25,60", // Portuguese (Brazil)
            "pt_PT": "25,60€", // Portuguese (Portugal)
            "ru_RU": "25,60€", // Russian (Russia)
            "sv_SE": "25,60€", // Swedish (Sweden)
            "tr_TR": "€25,60", // Turkish (Turkey)
            "zh_CN": "€25.60" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let normalFormattedAmount = normalAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(normalFormattedAmount, expected, "Formatted amount [\(normalFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_big_eur_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}١٠٬٢٤٩٫٥٥€", // Arabic (Saudi Arabia)
            "da_DK": "10.249,55€", // Danish (Denmark)
            "de_DE": "10.249,55€", // German (Germany)
            "en_GB": "€10,249.55", // English (United Kingdom)
            "en_US": "€10,249.55", // English (United States)
            "es_ES": "10.249,55€", // Spanish (Spain)
            "fi_FI": "10 249,55€", // Finnish (Finland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_BE": "10 249,55€", // French (Belgium) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "fr_CA": "10 249,55€", // French (Canada) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_FR": "10 249,55€", // French (France) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "hi_IN": "€10,249.55", // Hindi (India)
            "it_IT": "10.249,55€", // Italian (Italy)
            "ja_JP": "€10,249.55", // Japanese (Japan)
            "ko_KR": "€10,249.55", // Korean (South Korea)
            "nl_NL": "€10.249,55", // Dutch (Netherlands)
            "no_NO": "10 249,55€", // Norwegian (Norway) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pl_PL": "10 249,55€", // Polish (Poland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pt_BR": "€10.249,55", // Portuguese (Brazil)
            "pt_PT": "10 249,55€", // Portuguese (Portugal) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "ru_RU": "10 249,55€", // Russian (Russia) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "sv_SE": "10 249,55€", // Swedish (Sweden) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "tr_TR": "€10.249,55", // Turkish (Turkey)
            "zh_CN": "€10,249.55" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let bigFormattedAmount = bigAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(bigFormattedAmount, expected, "Formatted amount [\(bigFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_huge_eur_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٩٬٩٩٩٬٩٩٩٬٩٩٩٫٩٧€", // Arabic (Saudi Arabia)
            "da_DK": "9.999.999.999,97€", // Danish (Denmark)
            "de_DE": "9.999.999.999,97€", // German (Germany)
            "en_GB": "€9,999,999,999.97", // English (United Kingdom)
            "en_US": "€9,999,999,999.97", // English (United States)
            "es_ES": "9.999.999.999,97€", // Spanish (Spain)
            "fi_FI": "9 999 999 999,97€", // Finnish (Finland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_BE": "9 999 999 999,97€", // French (Belgium) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "fr_CA": "9 999 999 999,97€", // French (Canada) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_FR": "9 999 999 999,97€", // French (France) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "hi_IN": "€9,99,99,99,999.97", // Hindi (India)
            "it_IT": "9.999.999.999,97€", // Italian (Italy)
            "ja_JP": "€9,999,999,999.97", // Japanese (Japan)
            "ko_KR": "€9,999,999,999.97", // Korean (South Korea)
            "nl_NL": "€9.999.999.999,97", // Dutch (Netherlands)
            "no_NO": "9 999 999 999,97€", // Norwegian (Norway) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pl_PL": "9 999 999 999,97€", // Polish (Poland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pt_BR": "€9.999.999.999,97", // Portuguese (Brazil)
            "pt_PT": "9 999 999 999,97€", // Portuguese (Portugal) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "ru_RU": "9 999 999 999,97€", // Russian (Russia) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "sv_SE": "9 999 999 999,97€", // Swedish (Sweden) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "tr_TR": "€9.999.999.999,97", // Turkish (Turkey)
            "zh_CN": "€9,999,999,999.97" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let hugeFormattedAmount = hugeAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(hugeFormattedAmount, expected, "Formatted amount [\(hugeFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }
}
