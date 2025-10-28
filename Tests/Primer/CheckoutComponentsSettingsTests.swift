//
//  CheckoutComponentsSettingsTests.swift
//  PrimerSDK Tests
//
//  Tests for CheckoutComponents settings integration using direct PrimerSettings injection
//

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
class CheckoutComponentsSettingsTests: XCTestCase {

    // MARK: - Klarna Options Tests

    func testKlarnaOptionsNilHandling() {
        // Given: Settings without klarnaOptions
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                klarnaOptions: nil
            )
        )

        // Then: klarnaOptions should be nil and not crash
        XCTAssertNil(settings.paymentMethodOptions.klarnaOptions)
    }

    // MARK: - Payment Handling Tests

    func testPaymentHandlingDefaultsToAuto() {
        // Given: Settings with default paymentHandling
        let settings = PrimerSettings()

        // Then: paymentHandling should default to .auto
        XCTAssertEqual(settings.paymentHandling, .auto)
    }

    // MARK: - API Version Tests

    func testApiVersionDefaultsToLatest() {
        // Given: Settings with default apiVersion
        let settings = PrimerSettings()

        // Then: apiVersion should be the SDK's latest version
        XCTAssertEqual(settings.apiVersion, PrimerApiVersion.latest)
    }

    // MARK: - Card Form UI Options Tests

    func testCardFormUIOptionsNilWhenUnset() {
        // Given: Settings without cardFormUIOptions
        let settings = PrimerSettings()

        // Then: cardFormUIOptions should be nil and not crash
        XCTAssertNil(settings.uiOptions.cardFormUIOptions)
    }

    // MARK: - Client Session Caching Tests

    func testClientSessionCachingDefaultsToFalse() {
        // Given: Settings with default clientSessionCachingEnabled
        let settings = PrimerSettings()

        // Then: clientSessionCachingEnabled should default to false
        XCTAssertFalse(settings.clientSessionCachingEnabled)
    }

    // MARK: - Theme Tests

    func testThemeDefaultsToDefaultPrimerTheme() {
        // Given: Settings with default theme
        let settings = PrimerSettings()

        // Then: theme should default to PrimerTheme
        XCTAssertNotNil(settings.uiOptions.theme)
    }

    // MARK: - Locale Data Tests

    func testLocaleDataDefaultsToDeviceLocale() {
        // Given: Settings without custom localeData (uses device locale)
        let settings = PrimerSettings()

        // Then: localeData should default to device locale
        let defaultLocale = PrimerLocaleData()
        XCTAssertEqual(settings.localeData.languageCode, defaultLocale.languageCode)
        XCTAssertEqual(settings.localeData.localeCode, defaultLocale.localeCode)
    }

    func testLocaleDataCustomLanguageAndRegion() {
        // Given: Settings with custom language and region codes
        let settings = PrimerSettings(
            localeData: PrimerLocaleData(languageCode: "es", regionCode: "MX")
        )

        // Then: localeCode should be "es-MX" format
        XCTAssertEqual(settings.localeData.languageCode, "es")
        XCTAssertEqual(settings.localeData.regionCode, "MX")
        XCTAssertEqual(settings.localeData.localeCode, "es-MX")
    }

}
