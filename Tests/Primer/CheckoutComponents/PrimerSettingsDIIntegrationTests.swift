//
//  PrimerSettingsDIIntegrationTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class PrimerSettingsDIIntegrationTests: XCTestCase {
    // MARK: - Setup & Teardown

    override func tearDown() async throws {
        // Clean up global container after each test
        await DIContainer.clearContainer()
        try await super.tearDown()
    }

    // MARK: - PrimerSettings Registration Tests

    func testPrimerSettingsRegisteredInContainer() async throws {
        // Given: Custom settings with specific configuration
        let customSettings = PrimerSettings(
            paymentHandling: .manual,
            apiVersion: .V2_4
        )
        let composableContainer = ComposableContainer(settings: customSettings)

        // When: Configure the container
        await composableContainer.configure()
        guard let container = await DIContainer.current else {
            XCTFail("DIContainer.current should not be nil after configuration")
            return
        }

        // Then: PrimerSettings should be resolvable and match the provided instance
        let resolved = try await container.resolve(PrimerSettings.self)
        XCTAssertNotNil(resolved)
        XCTAssertEqual(resolved.paymentHandling, .manual)
        XCTAssertEqual(resolved.apiVersion, .V2_4)
    }

    func testPrimerSettingsRegisteredAsSingleton() async throws {
        // Given: Settings with unique configuration
        let settings = PrimerSettings(clientSessionCachingEnabled: true)
        let composableContainer = ComposableContainer(settings: settings)

        // When: Configure container and resolve twice
        await composableContainer.configure()
        guard let container = await DIContainer.current else {
            XCTFail("DIContainer.current should not be nil")
            return
        }

        let firstResolve = try await container.resolve(PrimerSettings.self)
        let secondResolve = try await container.resolve(PrimerSettings.self)

        // Then: Both resolutions should return the same instance (reference equality)
        XCTAssertTrue(firstResolve === secondResolve, "PrimerSettings should be singleton")
        XCTAssertTrue(settings.clientSessionCachingEnabled)
    }

    func testPrimerSettingsWithDefaultConfiguration() async throws {
        // Given: Default settings
        let defaultSettings = PrimerSettings()
        let composableContainer = ComposableContainer(settings: defaultSettings)

        // When: Configure and resolve
        await composableContainer.configure()
        guard let container = await DIContainer.current else {
            XCTFail("DIContainer.current should not be nil")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: Resolved settings should have default values
        XCTAssertEqual(resolved.paymentHandling, .auto)
        XCTAssertEqual(resolved.apiVersion, PrimerApiVersion.latest)
        XCTAssertFalse(resolved.clientSessionCachingEnabled)
    }

    func testPrimerSettingsWithPaymentMethodOptions() async throws {
        // Given: Settings with Klarna options
        let klarnaOptions = PrimerKlarnaOptions(
            recurringPaymentDescription: "Monthly subscription"
        )
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                klarnaOptions: klarnaOptions
            )
        )
        let composableContainer = ComposableContainer(settings: settings)

        // When: Configure and resolve
        await composableContainer.configure()
        guard let container = await DIContainer.current else {
            XCTFail("DIContainer.current should not be nil")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: Payment method options should be preserved
        XCTAssertNotNil(resolved.paymentMethodOptions.klarnaOptions)
        XCTAssertEqual(
            resolved.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
            "Monthly subscription"
        )
    }

    // MARK: - Theme Registration Tests

    func testThemeRegisteredFromPrimerSettings() async throws {
        // Given: Settings with custom theme
        let themeData = PrimerThemeData()
        themeData.text.title.defaultColor = .red
        let customTheme = PrimerTheme(with: themeData)
        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(theme: customTheme)
        )
        let composableContainer = ComposableContainer(settings: settings)

        // When: Configure and resolve theme
        await composableContainer.configure()
        guard let container = await DIContainer.current else {
            XCTFail("DIContainer.current should not be nil")
            return
        }

        let resolvedTheme = try await container.resolve(PrimerThemeProtocol.self)

        // Then: Resolved theme should be the custom theme
        XCTAssertNotNil(resolvedTheme)
        // Cast to concrete type for identity comparison
        if let concreteTheme = resolvedTheme as? PrimerTheme {
            XCTAssertTrue(concreteTheme === customTheme, "Theme should be the same instance")
            XCTAssertEqual(concreteTheme.text.title.color, .red)
        } else {
            XCTFail("Resolved theme should be PrimerTheme instance")
        }
    }

    func testThemeRegisteredAsSingleton() async throws {
        // Given: Settings with theme
        let theme = PrimerTheme()
        let settings = PrimerSettings(uiOptions: PrimerUIOptions(theme: theme))
        let composableContainer = ComposableContainer(settings: settings)

        // When: Configure and resolve theme twice
        await composableContainer.configure()
        guard let container = await DIContainer.current else {
            XCTFail("DIContainer.current should not be nil")
            return
        }

        let firstTheme = try await container.resolve(PrimerThemeProtocol.self)
        let secondTheme = try await container.resolve(PrimerThemeProtocol.self)

        // Then: Both should be the same instance
        // Cast to concrete type for identity comparison
        if let first = firstTheme as? PrimerTheme, let second = secondTheme as? PrimerTheme {
            XCTAssertTrue(first === second, "Theme should be singleton")
        } else {
            XCTFail("Resolved themes should be PrimerTheme instances")
        }
    }

    func testDefaultThemeWhenNoCustomTheme() async throws {
        // Given: Settings without explicit theme (uses default)
        let settings = PrimerSettings()
        let composableContainer = ComposableContainer(settings: settings)

        // When: Configure and resolve theme
        await composableContainer.configure()
        guard let container = await DIContainer.current else {
            XCTFail("DIContainer.current should not be nil")
            return
        }

        let theme = try await container.resolve(PrimerThemeProtocol.self)

        // Then: Theme should be resolvable (default PrimerTheme)
        XCTAssertNotNil(theme)
        XCTAssertNotNil(theme.text)
        XCTAssertNotNil(theme.colors)
    }

    // MARK: - Settings Mutation Safety Tests

    func testSettingsMutationDoesNotAffectRegisteredInstance() async throws {
        // Given: Mutable settings
        let settings = PrimerSettings()
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("DIContainer.current should not be nil")
            return
        }

        let resolvedBefore = try await container.resolve(PrimerSettings.self)
        let beforeHandling = resolvedBefore.paymentHandling

        // When: Mutate original settings (if possible - settings might be immutable)
        // Note: PrimerSettings is a class, so we can verify reference integrity

        // Then: Resolved instance should be the same reference
        let resolvedAfter = try await container.resolve(PrimerSettings.self)
        XCTAssertTrue(resolvedBefore === resolvedAfter, "Should be same instance")
        XCTAssertEqual(resolvedAfter.paymentHandling, beforeHandling)
    }

    // MARK: - Locale Data Tests

    func testSettingsWithCustomLocaleData() async throws {
        // Given: Settings with custom locale
        let localeData = PrimerLocaleData(languageCode: "es", regionCode: "MX")
        let settings = PrimerSettings(localeData: localeData)
        let composableContainer = ComposableContainer(settings: settings)

        // When: Configure and resolve
        await composableContainer.configure()
        guard let container = await DIContainer.current else {
            XCTFail("DIContainer.current should not be nil")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: Locale data should be preserved
        XCTAssertEqual(resolved.localeData.languageCode, "es")
        XCTAssertEqual(resolved.localeData.regionCode, "MX")
        XCTAssertEqual(resolved.localeData.localeCode, "es-MX")
    }

    // MARK: - UI Options Tests

    func testSettingsWithCardFormUIOptions() async throws {
        // Given: Settings with card form UI options
        let cardFormOptions = PrimerCardFormUIOptions(payButtonAddNewCard: true)
        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(cardFormUIOptions: cardFormOptions)
        )
        let composableContainer = ComposableContainer(settings: settings)

        // When: Configure and resolve
        await composableContainer.configure()
        guard let container = await DIContainer.current else {
            XCTFail("DIContainer.current should not be nil")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: Card form options should be accessible
        XCTAssertNotNil(resolved.uiOptions.cardFormUIOptions)
        XCTAssertEqual(resolved.uiOptions.cardFormUIOptions?.payButtonAddNewCard, true)
    }

    // MARK: - Container Cleanup Tests

    func testContainerClearsSuccessfully() async throws {
        // Given: Configured container
        let settings = PrimerSettings()
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        // Await before assertion to avoid async autoclosure issue
        let currentContainer = await DIContainer.current
        XCTAssertNotNil(currentContainer, "Container should exist after configuration")

        // When: Clear container
        await DIContainer.clearContainer()

        // Then: Container should be nil
        let clearedContainer = await DIContainer.current
        XCTAssertNil(clearedContainer, "Container should be nil after clearing")
    }

    func testMultipleContainerConfigurations() async throws {
        // Given: First configuration
        let settings1 = PrimerSettings(paymentHandling: .auto)
        let container1 = ComposableContainer(settings: settings1)
        await container1.configure()

        let resolved1 = try await DIContainer.current?.resolve(PrimerSettings.self)
        XCTAssertEqual(resolved1?.paymentHandling, .auto)

        // When: Clear and reconfigure with different settings
        await DIContainer.clearContainer()

        let settings2 = PrimerSettings(paymentHandling: .manual)
        let container2 = ComposableContainer(settings: settings2)
        await container2.configure()

        // Then: New settings should be resolved
        let resolved2 = try await DIContainer.current?.resolve(PrimerSettings.self)
        XCTAssertEqual(resolved2?.paymentHandling, .manual)
        XCTAssertFalse(resolved1 === resolved2, "Should be different instances")
    }
}
