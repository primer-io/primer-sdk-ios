//
//  CheckoutComponentsSettingsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class CheckoutComponentsSettingsTests: XCTestCase {

    func test_klarnaOptions_nilHandling() {
        // Given
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                klarnaOptions: nil
            )
        )

        // Then
        XCTAssertNil(settings.paymentMethodOptions.klarnaOptions)
    }

    func test_paymentHandling_defaultsToAuto() {
        // Given
        let settings = PrimerSettings()

        // Then
        XCTAssertEqual(settings.paymentHandling, .auto)
    }

    func test_apiVersion_defaultsToLatest() {
        // Given
        let settings = PrimerSettings()

        // Then
        XCTAssertEqual(settings.apiVersion, PrimerApiVersion.latest)
    }

    func test_cardFormUIOptions_nilWhenUnset() {
        // Given
        let settings = PrimerSettings()

        // Then
        XCTAssertNil(settings.uiOptions.cardFormUIOptions)
    }

    func test_clientSessionCaching_defaultsToFalse() {
        // Given
        let settings = PrimerSettings()

        // Then
        XCTAssertFalse(settings.clientSessionCachingEnabled)
    }

    func test_theme_defaultsToDefaultPrimerTheme() {
        // Given
        let settings = PrimerSettings()

        // Then
        XCTAssertNotNil(settings.uiOptions.theme)
    }

    func test_localeData_defaultsToDeviceLocale() {
        // Given
        let settings = PrimerSettings()
        let defaultLocale = PrimerLocaleData()

        // Then
        XCTAssertEqual(settings.localeData.languageCode, defaultLocale.languageCode)
        XCTAssertEqual(settings.localeData.localeCode, defaultLocale.localeCode)
    }

    func test_localeData_customLanguageAndRegion() {
        // Given
        let settings = PrimerSettings(
            localeData: PrimerLocaleData(languageCode: "es", regionCode: "MX")
        )

        // Then
        XCTAssertEqual(settings.localeData.languageCode, "es")
        XCTAssertEqual(settings.localeData.regionCode, "MX")
        XCTAssertEqual(settings.localeData.localeCode, "es-MX")
    }

    func test_dismissalMechanism_defaultsToGestures() {
        // Given
        let settings = PrimerSettings()

        // Then
        XCTAssertEqual(settings.uiOptions.dismissalMechanism, [.gestures])
        XCTAssertTrue(settings.uiOptions.dismissalMechanism.contains(.gestures))
        XCTAssertFalse(settings.uiOptions.dismissalMechanism.contains(.closeButton))
    }

    func test_dismissalMechanism_gesturesOnly() {
        // Given
        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(
                dismissalMechanism: [.gestures]
            )
        )

        // Then
        XCTAssertEqual(settings.uiOptions.dismissalMechanism.count, 1)
        XCTAssertTrue(settings.uiOptions.dismissalMechanism.contains(.gestures))
        XCTAssertFalse(settings.uiOptions.dismissalMechanism.contains(.closeButton))
    }

    func test_dismissalMechanism_closeButtonOnly() {
        // Given
        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(
                dismissalMechanism: [.closeButton]
            )
        )

        // Then
        XCTAssertEqual(settings.uiOptions.dismissalMechanism.count, 1)
        XCTAssertTrue(settings.uiOptions.dismissalMechanism.contains(.closeButton))
        XCTAssertFalse(settings.uiOptions.dismissalMechanism.contains(.gestures))
    }

    func test_dismissalMechanism_bothEnabled() {
        // Given
        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(
                dismissalMechanism: [.gestures, .closeButton]
            )
        )

        // Then
        XCTAssertEqual(settings.uiOptions.dismissalMechanism.count, 2)
        XCTAssertTrue(settings.uiOptions.dismissalMechanism.contains(.gestures))
        XCTAssertTrue(settings.uiOptions.dismissalMechanism.contains(.closeButton))
    }

    func test_dismissalMechanism_emptyArray_disablesBoth() {
        // Given
        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(
                dismissalMechanism: []
            )
        )

        // Then
        XCTAssertTrue(settings.uiOptions.dismissalMechanism.isEmpty)
    }
}
