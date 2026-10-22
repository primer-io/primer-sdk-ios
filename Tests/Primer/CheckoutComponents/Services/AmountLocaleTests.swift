//
//  AmountLocaleTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
import XCTest

/// The locale every printed amount is formatted in.
@available(iOS 15.0, *)
final class AmountLocaleTests: XCTestCase {

    // A default `PrimerLocaleData` seeds itself from the device, and its `localeCode` carries only a
    // language and a region. Rebuilding a `Locale` from it would drop the script subtag and the number
    // format chosen in Settings, so every merchant who never set one would see their amounts change.
    func test_locale_whenNotConfigured_isTheDeviceLocaleItself() {
        XCTAssertEqual(PrimerLocaleData().locale, Locale.current)
    }

    func test_locale_whenConfigured_isTheConfiguredOne() {
        let localeData = PrimerLocaleData(languageCode: "de", regionCode: "DE")

        XCTAssertEqual(localeData.locale, Locale(identifier: "de-DE"))
    }

    func test_locale_whenConfiguredWithLanguageOnly_dropsTheRegion() {
        XCTAssertEqual(PrimerLocaleData(languageCode: "fr").locale, Locale(identifier: "fr"))
    }

    func test_configurationService_exposesTheConfiguredLocale() {
        let settings = PrimerSettings(localeData: PrimerLocaleData(languageCode: "de", regionCode: "DE"))

        XCTAssertEqual(DefaultConfigurationService(settings: settings).locale, Locale(identifier: "de-DE"))
    }

    func test_configurationService_withoutAConfiguredLocale_usesTheDevice() {
        XCTAssertEqual(DefaultConfigurationService(settings: PrimerSettings()).locale, Locale.current)
    }

    // The point of routing every site through one locale: a configured locale reaches the output.
    func test_amountFormatting_honoursTheConfiguredLocale() {
        let currency = Currency(code: "EUR", decimalDigits: 2)
        let german = PrimerLocaleData(languageCode: "de", regionCode: "DE").locale
        let american = PrimerLocaleData(languageCode: "en", regionCode: "US").locale

        XCTAssertNotEqual(
            1234_56.toCurrencyString(currency: currency, locale: german),
            1234_56.toCurrencyString(currency: currency, locale: american)
        )
    }
}
