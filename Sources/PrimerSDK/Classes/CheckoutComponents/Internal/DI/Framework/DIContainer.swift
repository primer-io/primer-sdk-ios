//
//  DIContainer.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Provides global access to the current DI container with context management
@available(iOS 15.0, *)
public final class DIContainer: LogReporter {
    /// Singleton instance
    public static let shared = DIContainer()

    /// Isolated actor for thread-safe container operations
    private actor ContainerStorage {
        var container: (any ContainerProtocol)?
        var scopedContainers: [String: any ContainerProtocol] = [:]

        init(container: (any ContainerProtocol)? = nil) {
            self.container = container
        }

        func getContainer() -> (any ContainerProtocol)? {
            container
        }

        func setContainer(_ newContainer: (any ContainerProtocol)?) {
            container = newContainer
        }

        func getScopedContainer(for scopeId: String) -> (any ContainerProtocol)? {
            scopedContainers[scopeId]
        }

        func setScopedContainer(_ container: any ContainerProtocol, for scopeId: String) {
            scopedContainers[scopeId] = container
        }

        func removeScopedContainer(for scopeId: String) {
            scopedContainers[scopeId] = nil
        }
    }

    /// Thread-safe storage for containers
    private let storage: ContainerStorage

    /// Access to the current container (async)
    public static var current: (any ContainerProtocol)? {
        get async {
            await shared.storage.getContainer()
        }
    }

    /// Access to the current container (synchronous)
    /// Note: This uses a cached reference that is updated when the container changes
    /// MainActor isolation ensures thread safety for SwiftUI integration
    @MainActor
    public static var currentSync: (any ContainerProtocol)? {
        let container = shared.cachedContainer
        return container
    }

    /// Cached reference to the current container for synchronous access
    /// MainActor isolation prevents race conditions during updates
    @MainActor
    private var cachedContainer: (any ContainerProtocol)?

    /// Private initializer for singleton
    private init() {
        let container = Container()
        storage = ContainerStorage(container: container)

        // Initialize cached container on MainActor to prevent race conditions
        Task { @MainActor in
            self.cachedContainer = container
        }
    }

    /// Create a new container instance
    public static func createContainer() -> any ContainerProtocol {
        Container()
    }

    /// Set the global container instance
    public static func setContainer(_ container: any ContainerProtocol) async {
        await shared.storage.setContainer(container)

        await MainActor.run {
            shared.cachedContainer = container
        }
    }

    /// Clear the global container instance to free resources
    @MainActor
    public static func clearContainer() async {
        await shared.storage.setContainer(nil)
        shared.cachedContainer = nil
    }

    /// Set up a container with the application's dependencies
    public static func setupMainContainer() async {
        let container = Container()
        await registerDependencies(in: container)
        await setContainer(container)
    }

    /// Execute a block with a temporary container and restore the previous one afterward
    /// Useful for isolated testing contexts
    ///
    /// - Parameters:
    ///   - container: The container to use during the execution of the action
    ///   - action: The closure to execute with the temporary container
    /// - Returns: The result of the action
    /// - Throws: Any error thrown by the action
    @discardableResult
    public static func withContainer<T>(
        _ container: any ContainerProtocol,
        perform action: () async throws -> T
    ) async rethrows -> T {
        let previous = await shared.storage.getContainer()
        let previousSync = await MainActor.run { shared.cachedContainer }

        await shared.storage.setContainer(container)
        await MainActor.run {
            shared.cachedContainer = container
        }

        do {
            let result = try await action()
            await shared.storage.setContainer(previous)
            await MainActor.run {
                shared.cachedContainer = previousSync
            }
            return result
        } catch {
            await shared.storage.setContainer(previous)
            await MainActor.run {
                shared.cachedContainer = previousSync
            }
            throw error
        }
    }

    /// Add a scoped container
    public static func setScopedContainer(_ container: any ContainerProtocol, for scopeId: String) async {
        await shared.storage.setScopedContainer(container, for: scopeId)
    }

    /// Get a scoped container
    public static func scopedContainer(for scopeId: String) async -> (any ContainerProtocol)? {
        await shared.storage.getScopedContainer(for: scopeId)
    }

    /// Remove a scoped container
    public static func removeScopedContainer(for scopeId: String) async {
        await shared.storage.removeScopedContainer(for: scopeId)
    }

    /// Register the application's dependencies in the provided container
    private static func registerDependencies(in container: Container) async {
        Task {
            _ = try await container.register(ContainerProtocol.self).asSingleton().with { container in
                container
            }
        }
    }

    /// Create a container with mock dependencies for testing
    public static func createMockContainer() async -> any ContainerProtocol {
        let container = Container()
        await registerMockDependencies(in: container)
        return container
    }

    /// Register mock dependencies for testing
    private static func registerMockDependencies(in container: Container) async {
        await registerMockRepositories(container)
        await registerMockUseCases(container)
        await registerMockServices(container)
    }

    /// Register mock repositories
    private static func registerMockRepositories(_: Container) async {}

    /// Register mock use cases
    private static func registerMockUseCases(_: Container) async {}

    /// Register mock services
    private static func registerMockServices(_: Container) async {}
}
