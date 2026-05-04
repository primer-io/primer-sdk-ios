//
//  ContainerTestHelpers.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
enum ContainerTestHelpers {

    static func createTestContainer() async throws -> Container {
        let container = Container()

        // Register mock ConfigurationService
        let mockConfig = MockConfigurationService.withDefaultConfiguration()
        _ = try await container.register(ConfigurationService.self)
            .asSingleton()
            .with { _ in mockConfig }

        // Register mock AccessibilityAnnouncementService
        _ = try await container.register(AccessibilityAnnouncementService.self)
            .asSingleton()
            .with { _ in DefaultAccessibilityAnnouncementService(publisher: MockUIAccessibilityNotificationPublisher()) }

        // Register mock AnalyticsInteractor
        _ = try await container.register(CheckoutComponentsAnalyticsInteractorProtocol.self)
            .asSingleton()
            .with { _ in MockAnalyticsInteractor() }

        return container
    }

    /// Clears `DIContainer.shared` so registrations and singleton instances from one test do not leak into the next.
    /// Call in both `setUp` and `tearDown` of any test class that writes into `DIContainer.shared`.
    @MainActor
    static func resetSharedContainer() async {
        await DIContainer.clearContainer()
    }

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

    /// Creates a `DefaultCheckoutScope` that has already finished its async init (state = `.ready` or `.failure`).
    /// Use when a test depends on downstream code awaiting `checkoutScope.state` — without this, the scope may still
    /// be in `.initializing` when the test asserts, causing flakes.
    ///
    /// Installs a fresh minimal test container as `DIContainer.shared` so the scope's init can actually run.
    /// The test may later swap the container via `DIContainer.setContainer(_:)`; the scope's stored state survives.
    @MainActor
    static func createSettledCheckoutScope() async throws -> DefaultCheckoutScope {
        let container = try await createTestContainer()
        await DIContainer.setContainer(container)

        let navigator = CheckoutNavigator(coordinator: CheckoutCoordinator())
        let settings = PrimerSettings(
            paymentHandling: .manual,
            paymentMethodOptions: PrimerPaymentMethodOptions(),
            uiOptions: PrimerUIOptions(isInitScreenEnabled: false)
        )
        let scope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: settings,
            diContainer: DIContainer.shared,
            navigator: navigator
        )

        // Drain the state stream until the scope exits `.initializing`. Bounded by a generous timeout
        // so a broken init doesn't hang the suite forever.
        let deadline = Date().addingTimeInterval(5)
        for await state in scope.state {
            switch state {
            case .initializing:
                if Date() > deadline { return scope }
                continue
            default:
                return scope
            }
        }
        return scope
    }
}
