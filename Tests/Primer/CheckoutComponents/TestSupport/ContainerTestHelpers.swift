//
//  ContainerTestHelpers.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
enum ContainerTestHelpers {

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
            .with { _ in DefaultAccessibilityAnnouncementService(publisher: MockUIAccessibilityNotificationPublisher()) }

        // Register mock AnalyticsInteractor
        _ = try? await container.register(CheckoutComponentsAnalyticsInteractorProtocol.self)
            .asSingleton()
            .with { _ in MockAnalyticsInteractor() }

        return container
    }

    @MainActor
    static func createMockCheckoutScope() async -> DefaultCheckoutScope {
        let navigator = CheckoutNavigator(coordinator: CheckoutCoordinator())
        let settings = PrimerSettings(
            paymentHandling: .manual,
            paymentMethodOptions: PrimerPaymentMethodOptions()
        )
        return DefaultCheckoutScope(
            clientToken: "test-token",
            settings: settings,
            diContainer: DIContainer.shared,
            navigator: navigator
        )
    }
}
