//
//  PrimerSettingsIntegrationTests.swift
//  PrimerSDK Tests
//
//  Comprehensive integration tests for PrimerSettings across CheckoutComponents
//

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
        let customTheme = PrimerTheme()
        customTheme.text.title.color = .purple

        let klarnaOptions = PrimerKlarnaOptions(
            recurringPaymentDescription: "Test Subscription"
        )

        let settings = PrimerSettings(
            paymentHandling: .manual,
            clientSessionCachingEnabled: true,
            apiVersion: .V2_4,
            localeData: PrimerLocaleData(languageCode: "fr", regionCode: "FR"),
            paymentMethodOptions: PrimerPaymentMethodOptions(
                klarnaOptions: klarnaOptions,
                urlScheme: "testapp://payment"
            ),
            uiOptions: PrimerUIOptions(
                theme: customTheme,
                appearanceMode: .dark,
                cardFormUIOptions: PrimerCardFormUIOptions(payButtonAddNewCard: true)
            )
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
        XCTAssertEqual(resolvedSettings.paymentMethodOptions.urlScheme, "testapp://payment")
        XCTAssertEqual(resolvedSettings.uiOptions.appearanceMode, .dark)
        XCTAssertEqual(resolvedSettings.uiOptions.cardFormUIOptions?.payButtonAddNewCard, true)
        XCTAssertTrue(resolvedTheme === customTheme)
        XCTAssertEqual(resolvedTheme.text.title.color, .purple)
    }

    func testSettingsAndThemeAvailableSimultaneously() async throws {
        // Given: Settings with custom theme
        let customTheme = PrimerTheme()
        customTheme.colors.primary = .blue
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
        XCTAssertTrue(resolvedSettings.uiOptions.theme === resolvedTheme)
        XCTAssertEqual(resolvedTheme.colors.primary, .blue)
    }

    func testMultipleSettingsPropertiesAccessedConcurrently() async throws {
        // Given: Configured container with comprehensive settings
        let settings = PrimerSettings(
            paymentHandling: .manual,
            clientSessionCachingEnabled: true,
            apiVersion: .V2_4,
            localeData: PrimerLocaleData(languageCode: "es", regionCode: "MX")
        )

        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        // When: Multiple tasks access different settings properties concurrently
        await withTaskGroup(of: Bool.self) { group in
            // Task 1: Check payment handling
            group.addTask {
                if let s = try? await container.resolve(PrimerSettings.self) {
                    return s.paymentHandling == .manual
                }
                return false
            }

            // Task 2: Check caching
            group.addTask {
                if let s = try? await container.resolve(PrimerSettings.self) {
                    return s.clientSessionCachingEnabled == true
                }
                return false
            }

            // Task 3: Check API version
            group.addTask {
                if let s = try? await container.resolve(PrimerSettings.self) {
                    return s.apiVersion == .V2_4
                }
                return false
            }

            // Task 4: Check locale
            group.addTask {
                if let s = try? await container.resolve(PrimerSettings.self) {
                    return s.localeData.localeCode == "es-MX"
                }
                return false
            }

            // Then: All tasks should succeed
            var results: [Bool] = []
            for await result in group {
                results.append(result)
            }

            XCTAssertEqual(results.count, 4)
            XCTAssertTrue(results.allSatisfy { $0 }, "All concurrent accesses should succeed")
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
        XCTAssertTrue(firstTheme === secondTheme)
        XCTAssertTrue(firstTheme === customTheme)
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
        XCTAssertEqual(resolved.paymentMethodOptions.urlScheme, "testapp://")
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
        let customTheme = PrimerTheme()
        customTheme.text.title.fontSize = 24
        let cardFormOptions = PrimerCardFormUIOptions(payButtonAddNewCard: true)

        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(
                theme: customTheme,
                appearanceMode: .dark,
                isInitScreenEnabled: false,
                isSuccessScreenEnabled: true,
                isErrorScreenEnabled: true,
                cardFormUIOptions: cardFormOptions
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
        XCTAssertTrue(resolvedTheme === customTheme)
        XCTAssertEqual(resolvedTheme.text.title.fontSize, 24)
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

        XCTAssertNotNil(await DIContainer.current)

        // When: Clear container
        await DIContainer.clearContainer()

        // Then: Container should be cleared
        XCTAssertNil(await DIContainer.current)
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

    // MARK: - Performance Tests

    func testHighVolumeSettingsResolution() async throws {
        // Given: Configured container
        let settings = PrimerSettings(paymentHandling: .manual)
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        // When: Resolve settings 1000 times concurrently
        let startTime = Date()

        await withTaskGroup(of: PrimerSettings?.self) { group in
            for _ in 0..<1000 {
                group.addTask {
                    try? await container.resolve(PrimerSettings.self)
                }
            }

            var successCount = 0
            for await resolved in group {
                if resolved != nil {
                    successCount += 1
                }
            }

            let elapsed = Date().timeIntervalSince(startTime)

            // Then: All resolutions should succeed quickly
            XCTAssertEqual(successCount, 1000)
            XCTAssertLessThan(elapsed, 5.0, "Should complete in under 5 seconds")
        }
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
