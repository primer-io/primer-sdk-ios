//
//  USD_CurrencyFormattingTests.swift
//
//
//  Created by Onur Var on 20.03.2025.
//

@testable import PrimerSDK
import XCTest

class USD_CurrencyFormattingTests: XCTestCase {
    let zeroAmount: Int = 0
    let smallAmount: Int = 100
    let normalAmount: Int = 2560
    let bigAmount: Int = 1024955
    let hugeAmount: Int = 999999999997

    let sut = Currency(code: "USD", decimalDigits: 2)

    func test_zero_usd_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٠٫٠٠US$", // Arabic (Saudi Arabia)
            "da_DK": "0,00US$", // Danish (Denmark)
            "de_DE": "0,00US$", // German (Germany)
            "en_GB": "US$0.00", // English (United Kingdom)
            "en_US": "US$0.00", // English (United States)
            "es_ES": "0,00US$", // Spanish (Spain)
            "fi_FI": "0,00US$", // Finnish (Finland)
            "fr_BE": "0,00US$", // French (Belgium)
            "fr_CA": "0,00US$", // French (Canada)
            "fr_FR": "0,00US$", // French (France)
            "hi_IN": "US$0.00", // Hindi (India)
            "it_IT": "0,00US$", // Italian (Italy)
            "ja_JP": "US$0.00", // Japanese (Japan)
            "ko_KR": "US$0.00", // Korean (South Korea)
            "nl_NL": "US$0,00", // Dutch (Netherlands)
            "no_NO": "0,00US$", // Norwegian (Norway)
            "pl_PL": "0,00US$", // Polish (Poland)
            "pt_BR": "US$0,00", // Portuguese (Brazil)
            "pt_PT": "0,00US$", // Portuguese (Portugal)
            "ru_RU": "0,00US$", // Russian (Russia)
            "sv_SE": "0,00US$", // Swedish (Sweden)
            "tr_TR": "US$0,00", // Turkish (Turkey)
            "zh_CN": "US$0.00" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let zeroFormattedAmount = zeroAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(zeroFormattedAmount, expected, "Formatted amount [\(zeroFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_small_usd_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}١٫٠٠US$", // Arabic (Saudi Arabia)
            "da_DK": "1,00US$", // Danish (Denmark)
            "de_DE": "1,00US$", // German (Germany)
            "en_GB": "US$1.00", // English (United Kingdom)
            "en_US": "US$1.00", // English (United States)
            "es_ES": "1,00US$", // Spanish (Spain)
            "fi_FI": "1,00US$", // Finnish (Finland)
            "fr_BE": "1,00US$", // French (Belgium)
            "fr_CA": "1,00US$", // French (Canada)
            "fr_FR": "1,00US$", // French (France)
            "hi_IN": "US$1.00", // Hindi (India)
            "it_IT": "1,00US$", // Italian (Italy)
            "ja_JP": "US$1.00", // Japanese (Japan)
            "ko_KR": "US$1.00", // Korean (South Korea)
            "nl_NL": "US$1,00", // Dutch (Netherlands)
            "no_NO": "1,00US$", // Norwegian (Norway)
            "pl_PL": "1,00US$", // Polish (Poland)
            "pt_BR": "US$1,00", // Portuguese (Brazil)
            "pt_PT": "1,00US$", // Portuguese (Portugal)
            "ru_RU": "1,00US$", // Russian (Russia)
            "sv_SE": "1,00US$", // Swedish (Sweden)
            "tr_TR": "US$1,00", // Turkish (Turkey)
            "zh_CN": "US$1.00" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let smallFormattedAmount = smallAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(smallFormattedAmount, expected, "Formatted amount [\(smallFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_normal_usd_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٢٥٫٦٠US$", // Arabic (Saudi Arabia)
            "da_DK": "25,60US$", // Danish (Denmark)
            "de_DE": "25,60US$", // German (Germany)
            "en_GB": "US$25.60", // English (United Kingdom)
            "en_US": "US$25.60", // English (United States)
            "es_ES": "25,60US$", // Spanish (Spain)
            "fi_FI": "25,60US$", // Finnish (Finland)
            "fr_BE": "25,60US$", // French (Belgium)
            "fr_CA": "25,60US$", // French (Canada)
            "fr_FR": "25,60US$", // French (France)
            "hi_IN": "US$25.60", // Hindi (India)
            "it_IT": "25,60US$", // Italian (Italy)
            "ja_JP": "US$25.60", // Japanese (Japan)
            "ko_KR": "US$25.60", // Korean (South Korea)
            "nl_NL": "US$25,60", // Dutch (Netherlands)
            "no_NO": "25,60US$", // Norwegian (Norway)
            "pl_PL": "25,60US$", // Polish (Poland)
            "pt_BR": "US$25,60", // Portuguese (Brazil)
            "pt_PT": "25,60US$", // Portuguese (Portugal)
            "ru_RU": "25,60US$", // Russian (Russia)
            "sv_SE": "25,60US$", // Swedish (Sweden)
            "tr_TR": "US$25,60", // Turkish (Turkey)
            "zh_CN": "US$25.60" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let normalFormattedAmount = normalAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(normalFormattedAmount, expected, "Formatted amount [\(normalFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_big_usd_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}١٠٬٢٤٩٫٥٥US$", // Arabic (Saudi Arabia)
            "da_DK": "10.249,55US$", // Danish (Denmark)
            "de_DE": "10.249,55US$", // German (Germany)
            "en_GB": "US$10,249.55", // English (United Kingdom)
            "en_US": "US$10,249.55", // English (United States)
            "es_ES": "10.249,55US$", // Spanish (Spain)
            "fi_FI": "10 249,55US$", // Finnish (Finland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_BE": "10 249,55US$", // French (Belgium) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "fr_CA": "10 249,55US$", // French (Canada) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_FR": "10 249,55US$", // French (France) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "hi_IN": "US$10,249.55", // Hindi (India)
            "it_IT": "10.249,55US$", // Italian (Italy)
            "ja_JP": "US$10,249.55", // Japanese (Japan)
            "ko_KR": "US$10,249.55", // Korean (South Korea)
            "nl_NL": "US$10.249,55", // Dutch (Netherlands)
            "no_NO": "10 249,55US$", // Norwegian (Norway) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pl_PL": "10 249,55US$", // Polish (Poland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pt_BR": "US$10.249,55", // Portuguese (Brazil)
            "pt_PT": "10 249,55US$", // Portuguese (Portugal) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "ru_RU": "10 249,55US$", // Russian (Russia) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "sv_SE": "10 249,55US$", // Swedish (Sweden) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "tr_TR": "US$10.249,55", // Turkish (Turkey)
            "zh_CN": "US$10,249.55" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let bigFormattedAmount = bigAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(bigFormattedAmount, expected, "Formatted amount [\(bigFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_huge_usd_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٩٬٩٩٩٬٩٩٩٬٩٩٩٫٩٧US$", // Arabic (Saudi Arabia)
            "da_DK": "9.999.999.999,97US$", // Danish (Denmark)
            "de_DE": "9.999.999.999,97US$", // German (Germany)
            "en_GB": "US$9,999,999,999.97", // English (United Kingdom)
            "en_US": "US$9,999,999,999.97", // English (United States)
            "es_ES": "9.999.999.999,97US$", // Spanish (Spain)
            "fi_FI": "9 999 999 999,97US$", // Finnish (Finland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_BE": "9 999 999 999,97US$", // French (Belgium) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "fr_CA": "9 999 999 999,97US$", // French (Canada) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_FR": "9 999 999 999,97US$", // French (France) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "hi_IN": "US$9,99,99,99,999.97", // Hindi (India)
            "it_IT": "9.999.999.999,97US$", // Italian (Italy)
            "ja_JP": "US$9,999,999,999.97", // Japanese (Japan)
            "ko_KR": "US$9,999,999,999.97", // Korean (South Korea)
            "nl_NL": "US$9.999.999.999,97", // Dutch (Netherlands)
            "no_NO": "9 999 999 999,97US$", // Norwegian (Norway) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pl_PL": "9 999 999 999,97US$", // Polish (Poland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pt_BR": "US$9.999.999.999,97", // Portuguese (Brazil)
            "pt_PT": "9 999 999 999,97US$", // Portuguese (Portugal) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "ru_RU": "9 999 999 999,97US$", // Russian (Russia) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "sv_SE": "9 999 999 999,97US$", // Swedish (Sweden) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "tr_TR": "US$9.999.999.999,97", // Turkish (Turkey)
            "zh_CN": "US$9,999,999,999.97" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let hugeFormattedAmount = hugeAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(hugeFormattedAmount, expected, "Formatted amount [\(hugeFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }
}
