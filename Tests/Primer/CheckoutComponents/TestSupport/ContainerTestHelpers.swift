//
//  ContainerTestHelpers.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Shared test container creation helpers for CheckoutComponents tests.
/// Provides consistent container setup across all scope tests.
@available(iOS 15.0, *)
enum ContainerTestHelpers {

    /// Creates a test container with standard mock registrations.
    /// Registers: ConfigurationService, AccessibilityAnnouncementService, AnalyticsInteractor
    static func createTestContainer() async -> Container {
        let container = Container()

        // Register mock ConfigurationService
        let mockConfig = MockConfigurationService.withDefaultConfiguration()
        _ = try? await container.register(ConfigurationService.self)
            .asSingleton()
            .with { _ in mockConfig }

        // Register mock AccessibilityAnnouncementService
        _ = try? await container.register(AccessibilityAnnouncementService.self)
            .asSingleton()
            .with { _ in MockAccessibilityAnnouncementService() }

        // Register mock AnalyticsInteractor
        _ = try? await container.register(CheckoutComponentsAnalyticsInteractorProtocol.self)
            .asSingleton()
            .with { _ in MockAnalyticsInteractor() }

        return container
    }

    /// Creates a mock DefaultCheckoutScope for testing.
    /// Uses standard test settings with manual payment handling.
    @MainActor
    static func createMockCheckoutScope() async -> DefaultCheckoutScope {
        let navigator = CheckoutNavigator(coordinator: CheckoutCoordinator())
        let settings = PrimerSettings(
            paymentHandling: .manual,
            paymentMethodOptions: PrimerPaymentMethodOptions()
        )
        return DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: settings,
            diContainer: DIContainer.shared,
            navigator: navigator
        )
    }
}
