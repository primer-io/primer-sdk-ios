import Foundation
import SwiftUI

@available(iOS 15.0, *)
final class NavigationScope: DependencyScope, LogReporter {
    let scopeId = "navigation"
    private var scopedContainer: (any ContainerProtocol)?

    init() {
        // Empty initializer - container will be created during setupContainer()
    }

    func setupContainer() async {
        let container = DIContainer.createContainer()

        do {
            // Register CheckoutCoordinator
            _ = try await container.register(CheckoutCoordinator.self)
                .asSingleton()
                .with { container in
                    try await CheckoutCoordinator.create(container: container)
                }

            // Register any navigation-specific services
            try await registerNavigationServices(in: container)

            // Store the configured container
            self.scopedContainer = container

            // Register this scope with DIContainer
            await DIContainer.setScopedContainer(container, for: scopeId)

        } catch {
            logger.error(message: "❌ [NavigationScope] Failed to setup: \(error.localizedDescription)")
        }
    }

    func cleanupScope() async {
        // Clean up any resources
        scopedContainer = nil
        // Container removal is handled by DependencyScope extension
    }

    private func registerNavigationServices(in container: any ContainerProtocol) async throws {
        // Add any navigation-specific services here
        // Example: Analytics for navigation tracking
    }
}
