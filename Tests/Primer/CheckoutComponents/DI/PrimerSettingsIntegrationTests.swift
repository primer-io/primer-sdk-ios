//
//  PrimerSettingsIntegrationTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
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
        let klarnaOptions = PrimerKlarnaOptions(
            recurringPaymentDescription: TestData.Settings.testSubscriptionDescription
        )

        let settings = PrimerSettings(
            paymentHandling: .manual,
            localeData: PrimerLocaleData(
                languageCode: TestData.Locale.frenchLanguageCode,
                regionCode: TestData.Locale.franceRegionCode
            ),
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: TestData.Settings.testUrlScheme,
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
        XCTAssertEqual(resolvedSettings.localeData.localeCode, TestData.Locale.frenchFranceLocaleCode)
        XCTAssertEqual(
            resolvedSettings.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
            TestData.Settings.testSubscriptionDescription
        )
        // Test URL scheme via validation method instead of accessing private property
        XCTAssertNoThrow(try resolvedSettings.paymentMethodOptions.validUrlForUrlScheme())
        let urlScheme = try? resolvedSettings.paymentMethodOptions.validSchemeForUrlScheme()
        XCTAssertEqual(urlScheme, TestData.Settings.testUrlSchemePrefix)
        XCTAssertEqual(resolvedSettings.uiOptions.appearanceMode, .dark)
        XCTAssertEqual(resolvedSettings.uiOptions.cardFormUIOptions?.payButtonAddNewCard, true)
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
}
