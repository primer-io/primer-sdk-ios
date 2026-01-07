//
//  PrimerSettingsDIIntegrationTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

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

    // MARK: - Container Cleanup Tests

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
