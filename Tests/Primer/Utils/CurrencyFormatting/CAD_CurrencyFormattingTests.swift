//
//  CAD_CurrencyFormattingTests.swift
//
//
//  Created by Onur Var on 21.03.2025.
//

@testable import PrimerSDK
import XCTest

class CAD_CurrencyFormattingTests: XCTestCase {
    let zeroAmount: Int = 0
    let smallAmount: Int = 100
    let normalAmount: Int = 2560
    let bigAmount: Int = 1024955
    let hugeAmount: Int = 999999999997

    let sut = Currency(code: "CAD", decimalDigits: 2)

    func test_zero_cad_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٠٫٠٠CA$", // Arabic (Saudi Arabia)
            "da_DK": "0,00CA$", // Danish (Denmark)
            "de_DE": "0,00CA$", // German (Germany)
            "en_GB": "CA$0.00", // English (United Kingdom)
            "en_US": "CA$0.00", // English (United States)
            "es_ES": "0,00CA$", // Spanish (Spain)
            "fi_FI": "0,00CA$", // Finnish (Finland)
            "fr_BE": "0,00CA$", // French (Belgium)
            "fr_CA": "0,00CA$", // French (Canada)
            "fr_FR": "0,00CA$", // French (France)
            "hi_IN": "CA$0.00", // Hindi (India)
            "it_IT": "0,00CA$", // Italian (Italy)
            "ja_JP": "CA$0.00", // Japanese (Japan)
            "ko_KR": "CA$0.00", // Korean (South Korea)
            "nl_NL": "CA$0,00", // Dutch (Netherlands)
            "no_NO": "0,00CA$", // Norwegian (Norway)
            "pl_PL": "0,00CA$", // Polish (Poland)
            "pt_BR": "CA$0,00", // Portuguese (Brazil)
            "pt_PT": "0,00CA$", // Portuguese (Portugal)
            "ru_RU": "0,00CA$", // Russian (Russia)
            "sv_SE": "0,00CA$", // Swedish (Sweden)
            "tr_TR": "CA$0,00", // Turkish (Turkey)
            "zh_CN": "CA$0.00" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let zeroFormattedAmount = zeroAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(zeroFormattedAmount, expected, "Formatted amount [\(zeroFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_small_cad_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}١٫٠٠CA$", // Arabic (Saudi Arabia)
            "da_DK": "1,00CA$", // Danish (Denmark)
            "de_DE": "1,00CA$", // German (Germany)
            "en_GB": "CA$1.00", // English (United Kingdom)
            "en_US": "CA$1.00", // English (United States)
            "es_ES": "1,00CA$", // Spanish (Spain)
            "fi_FI": "1,00CA$", // Finnish (Finland)
            "fr_BE": "1,00CA$", // French (Belgium)
            "fr_CA": "1,00CA$", // French (Canada)
            "fr_FR": "1,00CA$", // French (France)
            "hi_IN": "CA$1.00", // Hindi (India)
            "it_IT": "1,00CA$", // Italian (Italy)
            "ja_JP": "CA$1.00", // Japanese (Japan)
            "ko_KR": "CA$1.00", // Korean (South Korea)
            "nl_NL": "CA$1,00", // Dutch (Netherlands)
            "no_NO": "1,00CA$", // Norwegian (Norway)
            "pl_PL": "1,00CA$", // Polish (Poland)
            "pt_BR": "CA$1,00", // Portuguese (Brazil)
            "pt_PT": "1,00CA$", // Portuguese (Portugal)
            "ru_RU": "1,00CA$", // Russian (Russia)
            "sv_SE": "1,00CA$", // Swedish (Sweden)
            "tr_TR": "CA$1,00", // Turkish (Turkey)
            "zh_CN": "CA$1.00" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let smallFormattedAmount = smallAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(smallFormattedAmount, expected, "Formatted amount [\(smallFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_normal_cad_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٢٥٫٦٠CA$", // Arabic (Saudi Arabia)
            "da_DK": "25,60CA$", // Danish (Denmark)
            "de_DE": "25,60CA$", // German (Germany)
            "en_GB": "CA$25.60", // English (United Kingdom)
            "en_US": "CA$25.60", // English (United States)
            "es_ES": "25,60CA$", // Spanish (Spain)
            "fi_FI": "25,60CA$", // Finnish (Finland)
            "fr_BE": "25,60CA$", // French (Belgium)
            "fr_CA": "25,60CA$", // French (Canada)
            "fr_FR": "25,60CA$", // French (France)
            "hi_IN": "CA$25.60", // Hindi (India)
            "it_IT": "25,60CA$", // Italian (Italy)
            "ja_JP": "CA$25.60", // Japanese (Japan)
            "ko_KR": "CA$25.60", // Korean (South Korea)
            "nl_NL": "CA$25,60", // Dutch (Netherlands)
            "no_NO": "25,60CA$", // Norwegian (Norway)
            "pl_PL": "25,60CA$", // Polish (Poland)
            "pt_BR": "CA$25,60", // Portuguese (Brazil)
            "pt_PT": "25,60CA$", // Portuguese (Portugal)
            "ru_RU": "25,60CA$", // Russian (Russia)
            "sv_SE": "25,60CA$", // Swedish (Sweden)
            "tr_TR": "CA$25,60", // Turkish (Turkey)
            "zh_CN": "CA$25.60" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let normalFormattedAmount = normalAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(normalFormattedAmount, expected, "Formatted amount [\(normalFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_big_cad_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}١٠٬٢٤٩٫٥٥CA$", // Arabic (Saudi Arabia)
            "da_DK": "10.249,55CA$", // Danish (Denmark)
            "de_DE": "10.249,55CA$", // German (Germany)
            "en_GB": "CA$10,249.55", // English (United Kingdom)
            "en_US": "CA$10,249.55", // English (United States)
            "es_ES": "10.249,55CA$", // Spanish (Spain)
            "fi_FI": "10 249,55CA$", // Finnish (Finland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_BE": "10 249,55CA$", // French (Belgium) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "fr_CA": "10 249,55CA$", // French (Canada) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_FR": "10 249,55CA$", // French (France) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "hi_IN": "CA$10,249.55", // Hindi (India)
            "it_IT": "10.249,55CA$", // Italian (Italy)
            "ja_JP": "CA$10,249.55", // Japanese (Japan)
            "ko_KR": "CA$10,249.55", // Korean (South Korea)
            "nl_NL": "CA$10.249,55", // Dutch (Netherlands)
            "no_NO": "10 249,55CA$", // Norwegian (Norway) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pl_PL": "10 249,55CA$", // Polish (Poland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pt_BR": "CA$10.249,55", // Portuguese (Brazil)
            "pt_PT": "10 249,55CA$", // Portuguese (Portugal) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "ru_RU": "10 249,55CA$", // Russian (Russia) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "sv_SE": "10 249,55CA$", // Swedish (Sweden) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "tr_TR": "CA$10.249,55", // Turkish (Turkey)
            "zh_CN": "CA$10,249.55" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let bigFormattedAmount = bigAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(bigFormattedAmount, expected, "Formatted amount [\(bigFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }

    func test_huge_cad_formats_correctly() throws {
        // Create a result dictionary for each locale
        let results: [String: String] = [
            "ar_SA": "\u{200F}٩٬٩٩٩٬٩٩٩٬٩٩٩٫٩٧CA$", // Arabic (Saudi Arabia)
            "da_DK": "9.999.999.999,97CA$", // Danish (Denmark)
            "de_DE": "9.999.999.999,97CA$", // German (Germany)
            "en_GB": "CA$9,999,999,999.97", // English (United Kingdom)
            "en_US": "CA$9,999,999,999.97", // English (United States)
            "es_ES": "9.999.999.999,97CA$", // Spanish (Spain)
            "fi_FI": "9 999 999 999,97CA$", // Finnish (Finland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_BE": "9 999 999 999,97CA$", // French (Belgium) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "fr_CA": "9 999 999 999,97CA$", // French (Canada) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "fr_FR": "9 999 999 999,97CA$", // French (France) // There is a special character in this string. U+202F (NARROW NO-BREAK SPACE)
            "hi_IN": "CA$9,99,99,99,999.97", // Hindi (India)
            "it_IT": "9.999.999.999,97CA$", // Italian (Italy)
            "ja_JP": "CA$9,999,999,999.97", // Japanese (Japan)
            "ko_KR": "CA$9,999,999,999.97", // Korean (South Korea)
            "nl_NL": "CA$9.999.999.999,97", // Dutch (Netherlands)
            "no_NO": "9 999 999 999,97CA$", // Norwegian (Norway) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pl_PL": "9 999 999 999,97CA$", // Polish (Poland) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "pt_BR": "CA$9.999.999.999,97", // Portuguese (Brazil)
            "pt_PT": "9 999 999 999,97CA$", // Portuguese (Portugal) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "ru_RU": "9 999 999 999,97CA$", // Russian (Russia) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "sv_SE": "9 999 999 999,97CA$", // Swedish (Sweden) // There is a special character in this string. U+00A0 (NO-BREAK SPACE)
            "tr_TR": "CA$9.999.999.999,97", // Turkish (Turkey)
            "zh_CN": "CA$9,999,999,999.97" // Chinese (China)
        ]

        // Test each locale
        for (locale, expected) in results {
            let hugeFormattedAmount = hugeAmount.toCurrencyString(currency: sut, locale: Locale(identifier: locale))
            XCTAssertEqual(hugeFormattedAmount, expected, "Formatted amount [\(hugeFormattedAmount)] is not correct for locale [\(locale)]")
        }
    }
}
