//
//  PrimerSettingsIntegrationTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class PrimerSettingsIntegrationTests: XCTestCase {

    // MARK: - Setup & Teardown

    private var savedContainer: ContainerProtocol?

    override func setUp() async throws {
        try await super.setUp()
        savedContainer = await DIContainer.current
    }

    override func tearDown() async throws {
        if let savedContainer {
            await DIContainer.setContainer(savedContainer)
        } else {
            await DIContainer.clearContainer()
        }
        try await super.tearDown()
    }

    // MARK: - End-to-End Settings Integration Tests

    func testSettingsFlowThroughEntireStack() async throws {
        // Given: Custom settings with full configuration
        let klarnaOptions = PrimerKlarnaOptions(
            recurringPaymentDescription: TestData.PaymentMethodOptions.testSubscription
        )

        let settings = PrimerSettings(
            paymentHandling: .manual,
            localeData: PrimerLocaleData(languageCode: TestData.Locale.french, regionCode: TestData.Locale.france),
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: TestData.PaymentMethodOptions.testAppUrl,
                klarnaOptions: klarnaOptions
            ),
            uiOptions: PrimerUIOptions(
                isInitScreenEnabled: nil,
                isSuccessScreenEnabled: nil,
                isErrorScreenEnabled: nil,
                dismissalMechanism: nil,
                cardFormUIOptions: PrimerCardFormUIOptions(payButtonAddNewCard: true),
                appearanceMode: .dark
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

        // Verify all aspects of settings
        XCTAssertEqual(resolvedSettings.paymentHandling, .manual)
        XCTAssertTrue(resolvedSettings.clientSessionCachingEnabled)
        XCTAssertEqual(resolvedSettings.apiVersion, .V2_4)
        XCTAssertEqual(resolvedSettings.localeData.localeCode, TestData.Locale.frenchFrance)
        XCTAssertEqual(
            resolvedSettings.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
            TestData.PaymentMethodOptions.testSubscription
        )
        // Test URL scheme via validation method instead of accessing private property
        XCTAssertNoThrow(try resolvedSettings.paymentMethodOptions.validUrlForUrlScheme())
        let urlScheme = try? resolvedSettings.paymentMethodOptions.validSchemeForUrlScheme()
        XCTAssertEqual(urlScheme, TestData.PaymentMethodOptions.testAppScheme)
        XCTAssertEqual(resolvedSettings.uiOptions.appearanceMode, .dark)
        XCTAssertEqual(resolvedSettings.uiOptions.cardFormUIOptions?.payButtonAddNewCard, true)
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

    // MARK: - Payment Method Options Integration Tests

    func testAllPaymentMethodOptionsAccessible() async throws {
        // Given: Settings with all payment method options configured
        let klarnaOptions = PrimerKlarnaOptions(
            recurringPaymentDescription: TestData.PaymentMethodOptions.subscription
        )
        let applePayOptions = PrimerApplePayOptions(
            merchantIdentifier: TestData.PaymentMethodOptions.testMerchantId,
            merchantName: TestData.PaymentMethodOptions.testMerchantName
        )

        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: TestData.PaymentMethodOptions.testAppUrlTrailing,
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
        XCTAssertEqual(urlScheme, TestData.PaymentMethodOptions.testAppScheme)
        XCTAssertNotNil(resolved.paymentMethodOptions.applePayOptions)
        XCTAssertEqual(
            resolved.paymentMethodOptions.applePayOptions?.merchantIdentifier,
            TestData.PaymentMethodOptions.testMerchantId
        )
        XCTAssertNotNil(resolved.paymentMethodOptions.klarnaOptions)
        XCTAssertEqual(
            resolved.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
            TestData.PaymentMethodOptions.subscription
        )
    }

    // MARK: - UI Options Integration Tests

    func testAllUIOptionsAccessible() async throws {
        // Given: Settings with all UI options configured
        let cardFormOptions = PrimerCardFormUIOptions(payButtonAddNewCard: true)

        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(
                isInitScreenEnabled: false,
                isSuccessScreenEnabled: true,
                isErrorScreenEnabled: true,
                dismissalMechanism: nil,
                cardFormUIOptions: cardFormOptions,
                appearanceMode: .dark
            )
        )

        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: All UI options should be accessible
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
        let localeData = PrimerLocaleData(languageCode: TestData.Locale.german, regionCode: TestData.Locale.germany)
        let settings = PrimerSettings(localeData: localeData)

        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: Locale data should be correctly propagated
        XCTAssertEqual(resolved.localeData.languageCode, TestData.Locale.german)
        XCTAssertEqual(resolved.localeData.regionCode, TestData.Locale.germany)
        XCTAssertEqual(resolved.localeData.localeCode, TestData.Locale.germanGermany)
    }

    func testLocaleDataWithLanguageOnly() async throws {
        // Given: Settings with language code only
        let localeData = PrimerLocaleData(languageCode: TestData.Locale.japanese, regionCode: nil)
        let settings = PrimerSettings(localeData: localeData)

        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: Locale should use language code only
        XCTAssertEqual(resolved.localeData.languageCode, TestData.Locale.japanese)
        XCTAssertNil(resolved.localeData.regionCode)
        XCTAssertEqual(resolved.localeData.localeCode, TestData.Locale.japanese)
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
