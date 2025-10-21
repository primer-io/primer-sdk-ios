//
//  HeadlessRepositorySettingsTests.swift
//  PrimerSDK Tests
//
//  Tests for HeadlessRepository settings injection and usage
//

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class HeadlessRepositorySettingsTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        // Ensure clean state
        await DIContainer.clearContainer()
    }

    override func tearDown() async throws {
        await DIContainer.clearContainer()
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

    func testPaymentHandlingAutoMode() async throws {
        // Given: Settings with auto payment handling
        let settings = PrimerSettings(paymentHandling: .auto)
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: Payment handling should be auto
        XCTAssertEqual(resolved.paymentHandling, .auto)
    }

    func testPaymentHandlingManualMode() async throws {
        // Given: Settings with manual payment handling
        let settings = PrimerSettings(paymentHandling: .manual)
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: Payment handling should be manual
        XCTAssertEqual(resolved.paymentHandling, .manual)
    }

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

    func testKlarnaOptionsAccessibleFromSettings() async throws {
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
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: Klarna options should be accessible
        XCTAssertNotNil(resolved.paymentMethodOptions.klarnaOptions)
        XCTAssertEqual(
            resolved.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
            "Monthly subscription"
        )
    }

    func testApplePayOptionsAccessibleFromSettings() async throws {
        // Given: Settings with Apple Pay options
        let applePayOptions = PrimerApplePayOptions(
            merchantIdentifier: "merchant.com.example.app",
            merchantName: "Example Merchant"
        )
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                applePayOptions: applePayOptions
            )
        )
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: Apple Pay options should be accessible
        XCTAssertNotNil(resolved.paymentMethodOptions.applePayOptions)
        XCTAssertEqual(
            resolved.paymentMethodOptions.applePayOptions?.merchantIdentifier,
            "merchant.com.example.app"
        )
        XCTAssertEqual(
            resolved.paymentMethodOptions.applePayOptions?.merchantName,
            "Example Merchant"
        )
    }

    func testURLSchemeAccessibleFromSettings() async throws {
        // Given: Settings with URL scheme
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: "myapp://payment"
            )
        )
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: URL scheme should be accessible
        XCTAssertEqual(resolved.paymentMethodOptions.urlScheme, "myapp://payment")
    }

    // MARK: - Settings Persistence Tests

    func testSettingsRemainConsistentAcrossMultipleResolves() async throws {
        // Given: Settings with specific configuration
        let settings = PrimerSettings(
            paymentHandling: .manual,
            clientSessionCachingEnabled: true,
            apiVersion: .V2_4
        )
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        // When: Resolve multiple times
        let resolve1 = try await container.resolve(PrimerSettings.self)
        let resolve2 = try await container.resolve(PrimerSettings.self)
        let resolve3 = try await container.resolve(PrimerSettings.self)

        // Then: All should be same instance with consistent values
        XCTAssertTrue(resolve1 === resolve2)
        XCTAssertTrue(resolve2 === resolve3)
        XCTAssertEqual(resolve1.paymentHandling, .manual)
        XCTAssertEqual(resolve2.paymentHandling, .manual)
        XCTAssertEqual(resolve3.paymentHandling, .manual)
        XCTAssertTrue(resolve1.clientSessionCachingEnabled)
        XCTAssertTrue(resolve2.clientSessionCachingEnabled)
        XCTAssertTrue(resolve3.clientSessionCachingEnabled)
    }

    // MARK: - Concurrent Settings Access Tests

    func testConcurrentSettingsAccess() async throws {
        // Given: Configured container
        let settings = PrimerSettings(paymentHandling: .manual)
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        // When: Access settings concurrently (simulating multiple HeadlessRepository operations)
        await withTaskGroup(of: PrimerSettings?.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    try? await container.resolve(PrimerSettings.self)
                }
            }

            // Then: All accesses should succeed
            var successCount = 0
            for await resolved in group {
                XCTAssertNotNil(resolved)
                XCTAssertEqual(resolved?.paymentHandling, .manual)
                successCount += 1
            }
            XCTAssertEqual(successCount, 50, "All concurrent accesses should succeed")
        }
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

    func testAPIVersionAccessibleFromSettings() async throws {
        // Given: Settings with specific API version
        let settings = PrimerSettings(apiVersion: .V2_4)
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: API version should be accessible
        XCTAssertEqual(resolved.apiVersion, .V2_4)
    }

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

    func testClientSessionCachingEnabledFromSettings() async throws {
        // Given: Settings with caching enabled
        let settings = PrimerSettings(clientSessionCachingEnabled: true)
        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        let resolved = try await container.resolve(PrimerSettings.self)

        // Then: Caching should be enabled
        XCTAssertTrue(resolved.clientSessionCachingEnabled)
    }

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
