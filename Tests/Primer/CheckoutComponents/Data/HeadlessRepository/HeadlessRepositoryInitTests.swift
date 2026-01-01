//
//  HeadlessRepositoryInitTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

// MARK: - Initialization Tests

@available(iOS 15.0, *)
final class HeadlessRepositoryInitializationTests: XCTestCase {

    func testInit_WithDefaultFactory_CreatesInstance() {
        // When
        let repository = HeadlessRepositoryImpl()

        // Then
        XCTAssertNotNil(repository)
    }

    func testInit_WithCustomFactory_UsesProvidedFactory() async throws {
        // Given
        var factoryCalled = false
        let mockActions = MockClientSessionActionsModule()

        let repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: {
                factoryCalled = true
                return mockActions
            }
        )

        // When
        await repository.selectCardNetwork(.visa)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(factoryCalled)
        XCTAssertEqual(mockActions.selectPaymentMethodCalls.count, 1)
    }
}

// MARK: - Configuration Service Factory Tests

@available(iOS 15.0, *)
final class ConfigurationServiceFactoryTests: XCTestCase {

    func testInit_WithConfigurationServiceFactory_UsesFactory() async throws {
        // Given
        var factoryCalled = false
        let mockConfigService = MockConfigurationService()
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        mockConfigService.apiConfiguration = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )

        let repository = HeadlessRepositoryImpl(
            configurationServiceFactory: {
                factoryCalled = true
                return mockConfigService
            }
        )

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertTrue(factoryCalled)
        XCTAssertEqual(methods.count, 1)
        XCTAssertEqual(methods.first?.type, "PAYMENT_CARD")
    }

    func testInit_WithoutFactory_ReturnsEmptyWithoutDI() async throws {
        // Given - No factory and no DI container
        let repository = HeadlessRepositoryImpl()

        // When
        let methods = try await repository.getPaymentMethods()

        // Then - Without DI container or factory, returns empty array
        XCTAssertTrue(methods.isEmpty)
    }

    func testGetPaymentMethods_CalledTwice_OnlyInjectsOnce() async throws {
        // Given
        var factoryCallCount = 0
        let mockConfigService = MockConfigurationService()
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        mockConfigService.apiConfiguration = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )

        let repository = HeadlessRepositoryImpl(
            configurationServiceFactory: {
                factoryCallCount += 1
                return mockConfigService
            }
        )

        // When - Call getPaymentMethods twice
        _ = try await repository.getPaymentMethods()
        _ = try await repository.getPaymentMethods()

        // Then - Factory should only be called once (idempotent injection)
        XCTAssertEqual(factoryCallCount, 1)
    }
}
