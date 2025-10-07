//
//  DIContainer.swift
//
//
//  Created by Boris on 7. 5. 2025.
//

import Foundation

/// Provides global access to the current DI container with context management
@available(iOS 15.0, *)
public final class DIContainer: LogReporter {
    /// Singleton instance
    public static let shared = DIContainer()

    /// Isolated actor for thread-safe container operations
    private actor ContainerStorage {
        var container: (any ContainerProtocol)?
        var scopedContainers: [String: (any ContainerProtocol)] = [:]

        init(container: (any ContainerProtocol)? = nil) {
            self.container = container
        }

        func getContainer() -> (any ContainerProtocol)? {
            return container
        }

        func setContainer(_ newContainer: (any ContainerProtocol)?) {
            container = newContainer
        }

        func getScopedContainer(for scopeId: String) -> (any ContainerProtocol)? {
            return scopedContainers[scopeId]
        }

        func setScopedContainer(_ container: (any ContainerProtocol), for scopeId: String) {
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
            return await shared.storage.getContainer()
        }
    }

    /// Access to the current container (synchronous)
    /// Note: This uses a cached reference that is updated when the container changes
    /// MainActor isolation ensures thread safety for SwiftUI integration
    @MainActor
    public static var currentSync: (any ContainerProtocol)? {
        let container = shared.cachedContainer
        if container == nil {
            // No container available
        }
        return container
    }

    /// Cached reference to the current container for synchronous access
    /// MainActor isolation prevents race conditions during updates
    @MainActor
    private var cachedContainer: (any ContainerProtocol)?

    /// Private initializer for singleton
    private init() {
        let container = Container()
        self.storage = ContainerStorage(container: container)

        // Initialize cached container on MainActor to prevent race conditions
        Task { @MainActor in
            self.cachedContainer = container
        }

        // DIContainer initialized
    }

    /// Create a new container instance
    public static func createContainer() -> any ContainerProtocol {
        // Creating new container
        return Container()
    }

    /// Set the global container instance
    public static func setContainer(_ container: any ContainerProtocol) async {
        // Setting global container
        await shared.storage.setContainer(container)

        // Update cached reference for synchronous access on MainActor
        await MainActor.run {
            shared.cachedContainer = container
        }
    }

    /// Set up a container with the application's dependencies
    public static func setupMainContainer() async {
        // Setting up main container
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
        // Switching to temporary container
        let previous = await shared.storage.getContainer()
        let previousSync = await MainActor.run { shared.cachedContainer }

        // Swap in immediately with proper MainActor isolation (thread-safe)
        await shared.storage.setContainer(container)
        await MainActor.run {
            shared.cachedContainer = container
        }

        do {
            let result = try await action()
            // Restoring previous container
            await shared.storage.setContainer(previous)
            await MainActor.run {
                shared.cachedContainer = previousSync  // Thread-safe restoration
            }
            return result
        } catch {
            // Restoring previous container after error
            await shared.storage.setContainer(previous)
            await MainActor.run {
                shared.cachedContainer = previousSync  // Thread-safe restoration after error
            }
            throw error
        }
    }

    /// Add a scoped container
    public static func setScopedContainer(_ container: any ContainerProtocol, for scopeId: String) async {
        // Setting scoped container
        await shared.storage.setScopedContainer(container, for: scopeId)
    }

    /// Get a scoped container
    public static func scopedContainer(for scopeId: String) async -> (any ContainerProtocol)? {
        return await shared.storage.getScopedContainer(for: scopeId)
    }

    /// Remove a scoped container
    public static func removeScopedContainer(for scopeId: String) async {
        // Removing scoped container
        await shared.storage.removeScopedContainer(for: scopeId)
    }

    /// Register the application's dependencies in the provided container
    private static func registerDependencies(in container: Container) async {
        // Registering application dependencies

        // Register the container itself
        Task {
            _ = try await container.register(ContainerProtocol.self).asSingleton().with { container in
                return container
            }
        }
    }

    /// Create a container with mock dependencies for testing
    public static func createMockContainer() async -> any ContainerProtocol {
        // Creating mock container
        let container = Container()
        await registerMockDependencies(in: container)
        return container
    }

    /// Register mock dependencies for testing
    private static func registerMockDependencies(in container: Container) async {
        // Registering mock dependencies

        // Register mocks using separate functions for better organization
        await registerMockRepositories(container)
        await registerMockUseCases(container)
        await registerMockServices(container)
    }

    /// Register mock repositories
    private static func registerMockRepositories(_ container: Container) async {
        // Registering mock repositories
        // Register mock repositories here
    }

    /// Register mock use cases
    private static func registerMockUseCases(_ container: Container) async {
        // Registering mock use cases
        // Register mock use cases here
    }

    /// Register mock services
    private static func registerMockServices(_ container: Container) async {
        // Registering mock services
        // Register mock services here
    }
}
