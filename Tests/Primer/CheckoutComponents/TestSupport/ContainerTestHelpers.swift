//
//  ContainerTestHelpers.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
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
}
