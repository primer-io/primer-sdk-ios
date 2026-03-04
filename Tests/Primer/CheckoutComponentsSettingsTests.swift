//
//  CheckoutComponentsSettingsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

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

    // MARK: - Dismissal Mechanism Tests

    func testDismissalMechanismDefaultsToGestures() {
        // Given: Settings with default dismissalMechanism
        let settings = PrimerSettings()

        // Then: dismissalMechanism should default to [.gestures] for backward compatibility with Drop-In UI
        XCTAssertEqual(settings.uiOptions.dismissalMechanism, [.gestures])
        XCTAssertTrue(settings.uiOptions.dismissalMechanism.contains(.gestures))
        XCTAssertFalse(settings.uiOptions.dismissalMechanism.contains(.closeButton))
    }

    func testDismissalMechanismGesturesOnly() {
        // Given: Settings with only gestures enabled
        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(
                dismissalMechanism: [.gestures]
            )
        )

        // Then: dismissalMechanism should contain only .gestures
        XCTAssertEqual(settings.uiOptions.dismissalMechanism.count, 1)
        XCTAssertTrue(settings.uiOptions.dismissalMechanism.contains(.gestures))
        XCTAssertFalse(settings.uiOptions.dismissalMechanism.contains(.closeButton))
    }

    func testDismissalMechanismCloseButtonOnly() {
        // Given: Settings with only close button enabled (APM use case)
        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(
                dismissalMechanism: [.closeButton]
            )
        )

        // Then: dismissalMechanism should contain only .closeButton
        XCTAssertEqual(settings.uiOptions.dismissalMechanism.count, 1)
        XCTAssertTrue(settings.uiOptions.dismissalMechanism.contains(.closeButton))
        XCTAssertFalse(settings.uiOptions.dismissalMechanism.contains(.gestures))
    }

    func testDismissalMechanismBothEnabled() {
        // Given: Settings with both gestures and close button enabled
        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(
                dismissalMechanism: [.gestures, .closeButton]
            )
        )

        // Then: dismissalMechanism should contain both options
        XCTAssertEqual(settings.uiOptions.dismissalMechanism.count, 2)
        XCTAssertTrue(settings.uiOptions.dismissalMechanism.contains(.gestures))
        XCTAssertTrue(settings.uiOptions.dismissalMechanism.contains(.closeButton))
    }

    func testDismissalMechanismEmptyArrayBehavior() {
        // Given: Settings with explicitly empty dismissalMechanism array
        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(
                dismissalMechanism: []
            )
        )

        // Then: dismissalMechanism should be empty (both disabled - matches Drop-In behavior)
        XCTAssertTrue(settings.uiOptions.dismissalMechanism.isEmpty)
        // Note: Empty array disables both gestures and close button (useful for embedding)
    }

}
