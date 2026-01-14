//
//  HeadlessRepositorySettingsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class HeadlessRepositorySettingsTests: XCTestCase {

    // MARK: - Setup & Teardown

    private var savedContainer: ContainerProtocol?

    override func setUp() async throws {
        try await super.setUp()
        savedContainer = await DIContainer.current
        await DIContainer.clearContainer()
    }

    override func tearDown() async throws {
        if let savedContainer {
            await DIContainer.setContainer(savedContainer)
        } else {
            await DIContainer.clearContainer()
        }
        try await super.tearDown()
    }

    // MARK: - Settings Injection Tests

    func testSettingsInjectedFromDIContainer() async throws {
        // Given: Configured DI container with settings
        let settings = PrimerSettings(paymentHandling: .manual)
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        // When: Resolve PrimerSettings from container
        let resolvedSettings = try await container.resolve(PrimerSettings.self)

        // Then: Settings should match the configured instance
        XCTAssertEqual(resolvedSettings.paymentHandling, .manual)
        XCTAssertTrue(resolvedSettings === settings, "Should be same instance")
    }

    func testSettingsLazyInjection() async throws {
        // Given: Configured container with settings
        let settings = PrimerSettings(
            paymentHandling: .auto,
            apiVersion: .V2_4
        )
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        // When: Resolve settings (simulating lazy injection in HeadlessRepositoryImpl)
        let firstResolve = try await container.resolve(PrimerSettings.self)
        let secondResolve = try await container.resolve(PrimerSettings.self)

        // Then: Both resolutions should return same instance
        XCTAssertTrue(firstResolve === secondResolve, "Settings should be singleton")
        XCTAssertEqual(firstResolve.paymentHandling, .auto)
        XCTAssertEqual(firstResolve.apiVersion, .V2_4)
    }

    func testSettingsNotAvailableWhenContainerNotConfigured() async {
        // Given: No container configured
        await DIContainer.clearContainer()

        // When: Try to access current container
        let container = await DIContainer.current

        // Then: Container should be nil
        XCTAssertNil(container, "Container should not exist when not configured")
    }

    // MARK: - Payment Handling Mode Tests

    func testPaymentHandlingDefaultsToAuto() async throws {
        // Given: Settings without explicit payment handling (uses default)
        let settings = PrimerSettings()
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: Payment handling should default to auto
        XCTAssertEqual(resolved.paymentHandling, .auto)
    }

    // MARK: - Payment Method Options Tests

    func testURLSchemeAccessibleFromSettings() async throws {
        // Given: Settings with URL scheme
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: TestData.PaymentMethodOptions.myAppUrlScheme
            )
        )
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: URL scheme should be accessible via validation methods
        XCTAssertNoThrow(try resolved.paymentMethodOptions.validUrlForUrlScheme())
        let urlScheme = try? resolved.paymentMethodOptions.validSchemeForUrlScheme()
        XCTAssertEqual(urlScheme, TestData.PaymentMethodOptions.myAppScheme)
    }

    // MARK: - Settings Isolation Tests

    func testSettingsIsolatedBetweenContainerInstances() async throws {
        // Given: First container with auto mode
        let settings1 = PrimerSettings(paymentHandling: .auto)
        let container1 = ComposableContainer(settings: settings1)
        await container1.configure()

        let resolved1 = try await DIContainer.current?.resolve(PrimerSettings.self)
        XCTAssertEqual(resolved1?.paymentHandling, .auto)

        // When: Clear and create new container with manual mode
        await DIContainer.clearContainer()

        let settings2 = PrimerSettings(paymentHandling: .manual)
        let container2 = ComposableContainer(settings: settings2)
        await container2.configure()

        let resolved2 = try await DIContainer.current?.resolve(PrimerSettings.self)

        // Then: Second container should have different settings
        XCTAssertEqual(resolved2?.paymentHandling, .manual)
        XCTAssertFalse(resolved1 === resolved2, "Should be different instances")
    }

    // MARK: - API Version Tests

    func testAPIVersionDefaultsToLatest() async throws {
        // Given: Settings without explicit API version
        let settings = PrimerSettings()
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: API version should default to latest
        XCTAssertEqual(resolved.apiVersion, PrimerApiVersion.latest)
    }

    // MARK: - Client Session Caching Tests

    func testClientSessionCachingDisabledByDefault() async throws {
        // Given: Settings without explicit caching configuration
        let settings = PrimerSettings()
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: Caching should be disabled by default
        XCTAssertFalse(resolved.clientSessionCachingEnabled)
    }
}
