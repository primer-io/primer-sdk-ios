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

    func testKlarnaOptionsAreAccessible() {
        // Given: Settings with klarnaOptions configured
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                klarnaOptions: PrimerKlarnaOptions(
                    recurringPaymentDescription: "Monthly subscription"
                )
            )
        )

        // Then: klarnaOptions should be accessible directly from settings
        XCTAssertNotNil(settings.paymentMethodOptions.klarnaOptions)
        XCTAssertEqual(
            settings.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
            "Monthly subscription"
        )
    }

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

    func testPaymentHandlingReturnsManualWhenConfigured() {
        // Given: Settings with manual paymentHandling
        let settings = PrimerSettings(paymentHandling: .manual)

        // Then: paymentHandling should be .manual
        XCTAssertEqual(settings.paymentHandling, .manual)
    }

    // MARK: - API Version Tests

    func testApiVersionDefaultsToLatest() {
        // Given: Settings with default apiVersion
        let settings = PrimerSettings()

        // Then: apiVersion should be the SDK's latest version
        XCTAssertEqual(settings.apiVersion, PrimerApiVersion.latest)
    }

    func testApiVersionCanBeSet() {
        // Given: Settings with specific apiVersion
        let settings = PrimerSettings(apiVersion: .V2_4)

        // Then: apiVersion should reflect the provided value
        XCTAssertEqual(settings.apiVersion, .V2_4)
    }

    // MARK: - Card Form UI Options Tests

    func testCardFormUIOptionsReturnsTrueWhenConfigured() {
        // Given: Settings with cardFormUIOptions configured to show "Add new card"
        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(
                cardFormUIOptions: PrimerCardFormUIOptions(payButtonAddNewCard: true)
            )
        )

        // Then: Property should return the configured value
        XCTAssertEqual(settings.uiOptions.cardFormUIOptions?.payButtonAddNewCard, true)
    }

    func testCardFormUIOptionsNilWhenUnset() {
        // Given: Settings without cardFormUIOptions
        let settings = PrimerSettings()

        // Then: cardFormUIOptions should be nil and not crash
        XCTAssertNil(settings.uiOptions.cardFormUIOptions)
    }

    func testCardFormUIOptionsPayButtonAddNewCardFalse() {
        // Given: Settings with payButtonAddNewCard = false (for payment mode)
        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(
                cardFormUIOptions: PrimerCardFormUIOptions(payButtonAddNewCard: false)
            )
        )

        // Then: payButtonAddNewCard should be false
        XCTAssertEqual(settings.uiOptions.cardFormUIOptions?.payButtonAddNewCard, false)
    }

    // MARK: - Client Session Caching Tests

    func testClientSessionCachingDefaultsToFalse() {
        // Given: Settings with default clientSessionCachingEnabled
        let settings = PrimerSettings()

        // Then: clientSessionCachingEnabled should default to false
        XCTAssertFalse(settings.clientSessionCachingEnabled)
    }

    func testClientSessionCachingCanBeEnabled() {
        // Given: Settings with caching explicitly enabled
        let settings = PrimerSettings(clientSessionCachingEnabled: true)

        // Then: clientSessionCachingEnabled should be true
        XCTAssertTrue(settings.clientSessionCachingEnabled)
    }

    // MARK: - Theme Tests

    func testThemeDefaultsToDefaultPrimerTheme() {
        // Given: Settings with default theme
        let settings = PrimerSettings()

        // Then: theme should default to PrimerTheme
        XCTAssertNotNil(settings.uiOptions.theme)
    }

    func testCustomThemeIsAccessible() {
        // Given: Settings with custom theme
        let customTheme = PrimerTheme()
        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(
                theme: customTheme
            )
        )

        // Then: Custom theme should be accessible from settings
        XCTAssertNotNil(settings.uiOptions.theme)
        XCTAssertTrue(settings.uiOptions.theme === customTheme)
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

    func testLocaleDataCustomLanguageCode() {
        // Given: Settings with custom language code only
        let settings = PrimerSettings(
            localeData: PrimerLocaleData(languageCode: "es", regionCode: nil)
        )

        // Then: Language code should be "es" and localeCode should match
        XCTAssertEqual(settings.localeData.languageCode, "es")
        XCTAssertEqual(settings.localeData.localeCode, "es")
        XCTAssertNil(settings.localeData.regionCode)
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
