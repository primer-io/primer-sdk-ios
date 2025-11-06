//
//  PrimerSettingsIntegrationTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class PrimerSettingsIntegrationTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func tearDown() async throws {
        await DIContainer.clearContainer()
        try await super.tearDown()
    }

    // MARK: - End-to-End Settings Integration Tests

    func testSettingsFlowThroughEntireStack() async throws {
        // Given: Custom settings with full configuration
        let themeData = PrimerThemeData()
        themeData.text.title.defaultColor = .purple
        let customTheme = PrimerTheme(with: themeData)

        let klarnaOptions = PrimerKlarnaOptions(
            recurringPaymentDescription: "Test Subscription"
        )

        let settings = PrimerSettings(
            paymentHandling: .manual,
            localeData: PrimerLocaleData(languageCode: "fr", regionCode: "FR"),
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: "testapp://payment",
                klarnaOptions: klarnaOptions
            ),
            uiOptions: PrimerUIOptions(
                isInitScreenEnabled: nil,
                isSuccessScreenEnabled: nil,
                isErrorScreenEnabled: nil,
                dismissalMechanism: nil,
                cardFormUIOptions: PrimerCardFormUIOptions(payButtonAddNewCard: true),
                appearanceMode: .dark,
                theme: customTheme
            ),
            clientSessionCachingEnabled: true,
            apiVersion: .V2_4
        )

        // When: Configure container with these settings
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        // Then: All settings should be accessible and correct
        let resolvedSettings = try await container.resolve(PrimerSettings.self)
        let resolvedTheme = try await container.resolve(PrimerThemeProtocol.self)

        // Verify all aspects of settings
        XCTAssertEqual(resolvedSettings.paymentHandling, .manual)
        XCTAssertTrue(resolvedSettings.clientSessionCachingEnabled)
        XCTAssertEqual(resolvedSettings.apiVersion, .V2_4)
        XCTAssertEqual(resolvedSettings.localeData.localeCode, "fr-FR")
        XCTAssertEqual(
            resolvedSettings.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
            "Test Subscription"
        )
        // Test URL scheme via validation method instead of accessing private property
        XCTAssertNoThrow(try resolvedSettings.paymentMethodOptions.validUrlForUrlScheme())
        let urlScheme = try? resolvedSettings.paymentMethodOptions.validSchemeForUrlScheme()
        XCTAssertEqual(urlScheme, "testapp")
        XCTAssertEqual(resolvedSettings.uiOptions.appearanceMode, .dark)
        XCTAssertEqual(resolvedSettings.uiOptions.cardFormUIOptions?.payButtonAddNewCard, true)
        // Cast protocol to concrete type for identity comparison
        if let concreteTheme = resolvedTheme as? PrimerTheme {
            XCTAssertTrue(concreteTheme === customTheme)
            XCTAssertEqual(concreteTheme.text.title.color, .purple)
        } else {
            XCTFail("Resolved theme should be PrimerTheme instance")
        }
    }

    func testSettingsAndThemeAvailableSimultaneously() async throws {
        // Given: Settings with custom theme
        let themeData = PrimerThemeData()
        themeData.colors.primary = .blue
        let customTheme = PrimerTheme(with: themeData)
        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(theme: customTheme)
        )

        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        // When: Resolve both settings and theme concurrently
        async let settingsTask = container.resolve(PrimerSettings.self)
        async let themeTask = container.resolve(PrimerThemeProtocol.self)

        let (resolvedSettings, resolvedTheme) = try await (settingsTask, themeTask)

        // Then: Both should be available and consistent
        XCTAssertNotNil(resolvedSettings)
        XCTAssertNotNil(resolvedTheme)
        XCTAssertTrue(resolvedSettings.uiOptions.theme === customTheme)
        if let concreteTheme = resolvedTheme as? PrimerTheme {
            XCTAssertTrue(concreteTheme === customTheme)
            XCTAssertEqual(concreteTheme.colors.primary, .blue)
        } else {
            XCTFail("Resolved theme should be PrimerTheme instance")
        }
    }

    // MARK: - Settings Immutability Tests

    func testSettingsReferenceStabilityAcrossResolutions() async throws {
        // Given: Configured container
        let settings = PrimerSettings(paymentHandling: .auto)
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        // When: Resolve settings multiple times
        let firstResolve = try await container.resolve(PrimerSettings.self)
        let secondResolve = try await container.resolve(PrimerSettings.self)
        let thirdResolve = try await container.resolve(PrimerSettings.self)

        // Then: All should be same instance (reference equality)
        XCTAssertTrue(firstResolve === secondResolve)
        XCTAssertTrue(secondResolve === thirdResolve)
        XCTAssertTrue(firstResolve === settings)
    }

    func testThemeReferenceStabilityAcrossResolutions() async throws {
        // Given: Settings with theme
        let customTheme = PrimerTheme()
        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(theme: customTheme)
        )
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        // When: Resolve theme multiple times
        let firstTheme = try await container.resolve(PrimerThemeProtocol.self)
        let secondTheme = try await container.resolve(PrimerThemeProtocol.self)

        // Then: All should be same instance
        // Cast to concrete type for identity comparison
        if let first = firstTheme as? PrimerTheme, let second = secondTheme as? PrimerTheme {
            XCTAssertTrue(first === second)
            XCTAssertTrue(first === customTheme)
        } else {
            XCTFail("Resolved themes should be PrimerTheme instances")
        }
    }

    // MARK: - Payment Method Options Integration Tests

    func testAllPaymentMethodOptionsAccessible() async throws {
        // Given: Settings with all payment method options configured
        let klarnaOptions = PrimerKlarnaOptions(
            recurringPaymentDescription: "Subscription"
        )
        let applePayOptions = PrimerApplePayOptions(
            merchantIdentifier: "merchant.test",
            merchantName: "Test Merchant"
        )

        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: "testapp://",
                applePayOptions: applePayOptions,
                klarnaOptions: klarnaOptions
            )
        )

        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: All payment method options should be accessible
        // Test URL scheme via validation method instead of accessing private property
        XCTAssertNoThrow(try resolved.paymentMethodOptions.validUrlForUrlScheme())
        let urlScheme = try? resolved.paymentMethodOptions.validSchemeForUrlScheme()
        XCTAssertEqual(urlScheme, "testapp")
        XCTAssertNotNil(resolved.paymentMethodOptions.applePayOptions)
        XCTAssertEqual(
            resolved.paymentMethodOptions.applePayOptions?.merchantIdentifier,
            "merchant.test"
        )
        XCTAssertNotNil(resolved.paymentMethodOptions.klarnaOptions)
        XCTAssertEqual(
            resolved.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
            "Subscription"
        )
    }

    // MARK: - UI Options Integration Tests

    func testAllUIOptionsAccessible() async throws {
        // Given: Settings with all UI options configured
        let themeData = PrimerThemeData()
        themeData.text.title.fontSize = 24
        let customTheme = PrimerTheme(with: themeData)
        let cardFormOptions = PrimerCardFormUIOptions(payButtonAddNewCard: true)

        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(
                isInitScreenEnabled: false,
                isSuccessScreenEnabled: true,
                isErrorScreenEnabled: true,
                dismissalMechanism: nil,
                cardFormUIOptions: cardFormOptions,
                appearanceMode: .dark,
                theme: customTheme
            )
        )

        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)
        let resolvedTheme = try await container.resolve(PrimerThemeProtocol.self)

        // Then: All UI options should be accessible
        if let concreteTheme = resolvedTheme as? PrimerTheme {
            XCTAssertTrue(concreteTheme === customTheme)
            XCTAssertEqual(concreteTheme.text.title.fontSize, 24)
        } else {
            XCTFail("Resolved theme should be PrimerTheme instance")
        }
        XCTAssertEqual(resolved.uiOptions.appearanceMode, .dark)
        XCTAssertFalse(resolved.uiOptions.isInitScreenEnabled)
        XCTAssertTrue(resolved.uiOptions.isSuccessScreenEnabled)
        XCTAssertTrue(resolved.uiOptions.isErrorScreenEnabled)
        XCTAssertNotNil(resolved.uiOptions.cardFormUIOptions)
        XCTAssertEqual(resolved.uiOptions.cardFormUIOptions?.payButtonAddNewCard, true)
    }

    // MARK: - Locale Integration Tests

    func testLocaleDataPropagation() async throws {
        // Given: Settings with specific locale
        let localeData = PrimerLocaleData(languageCode: "de", regionCode: "DE")
        let settings = PrimerSettings(localeData: localeData)

        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: Locale data should be correctly propagated
        XCTAssertEqual(resolved.localeData.languageCode, "de")
        XCTAssertEqual(resolved.localeData.regionCode, "DE")
        XCTAssertEqual(resolved.localeData.localeCode, "de-DE")
    }

    func testLocaleDataWithLanguageOnly() async throws {
        // Given: Settings with language code only
        let localeData = PrimerLocaleData(languageCode: "ja", regionCode: nil)
        let settings = PrimerSettings(localeData: localeData)

        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: Locale should use language code only
        XCTAssertEqual(resolved.localeData.languageCode, "ja")
        XCTAssertNil(resolved.localeData.regionCode)
        XCTAssertEqual(resolved.localeData.localeCode, "ja")
    }

    // MARK: - Container Lifecycle Tests

    func testSettingsPersisThroughContainerLifecycle() async throws {
        // Given: Initial configuration
        let settings1 = PrimerSettings(paymentHandling: .auto)
        let container1 = ComposableContainer(settings: settings1)
        await container1.configure()

        let initialResolve = try await DIContainer.current?.resolve(PrimerSettings.self)
        XCTAssertEqual(initialResolve?.paymentHandling, .auto)

        // When: Reconfigure container (without clearing)
        let settings2 = PrimerSettings(paymentHandling: .manual)
        let container2 = ComposableContainer(settings: settings2)
        await container2.configure()

        let afterResolve = try await DIContainer.current?.resolve(PrimerSettings.self)

        // Then: Settings should be updated to new configuration
        XCTAssertEqual(afterResolve?.paymentHandling, .manual)
    }

    func testContainerClearRemovesSettings() async throws {
        // Given: Configured container
        let settings = PrimerSettings()
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        // Await before assertion to avoid async autoclosure issue
        let currentContainer = await DIContainer.current
        XCTAssertNotNil(currentContainer)

        // When: Clear container
        await DIContainer.clearContainer()

        // Then: Container should be cleared
        let clearedContainer = await DIContainer.current
        XCTAssertNil(clearedContainer)
    }

    // MARK: - Error Handling Tests

    func testSettingsResolutionFailsWhenContainerNotConfigured() async {
        // Given: No container configured
        await DIContainer.clearContainer()

        // When: Try to resolve settings
        let container = await DIContainer.current

        // Then: Container should be nil
        XCTAssertNil(container)
    }

    // MARK: - Default Values Tests

    func testDefaultSettingsValues() async throws {
        // Given: Default settings (no customization)
        let settings = PrimerSettings()
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: All defaults should be correct
        XCTAssertEqual(resolved.paymentHandling, .auto)
        XCTAssertFalse(resolved.clientSessionCachingEnabled)
        XCTAssertEqual(resolved.apiVersion, PrimerApiVersion.latest)
        XCTAssertEqual(resolved.uiOptions.appearanceMode, .system)
        XCTAssertNotNil(resolved.uiOptions.theme) // Default theme exists
        XCTAssertNil(resolved.uiOptions.cardFormUIOptions)
        XCTAssertNil(resolved.paymentMethodOptions.klarnaOptions)
        XCTAssertNil(resolved.paymentMethodOptions.applePayOptions)
    }
}
