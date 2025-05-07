//
//  DIContainer.swift
//
//
//  Created by Boris on 7. 5. 2025..
//

import Foundation

/// Provides global access to the current DI container with context management
final class DIContainer {
    /// Thread-safe access to current container
    private static let lock = NSLock()

    /// The current container instance
    private static var _current: ContainerProtocol?
    static var current: ContainerProtocol? {
        get {
            lock.lock(); defer { lock.unlock() }
            return _current
        }
        set {
            lock.lock(); defer { lock.unlock() }
            _current = newValue
        }
    }

    /// Create a new container instance
    static func createContainer() -> ContainerProtocol {
        return Container()
    }

    /// Set up a container with the application's dependencies
    static func setupMainContainer() {
        let container = createContainer()
        registerDependencies(in: container)
        current = container
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
    static func withContainer<T>(_ container: ContainerProtocol, perform action: () throws -> T) rethrows -> T {
        lock.lock()
        let previous = current
        current = container
        lock.unlock()

        defer {
            lock.lock()
            current = previous
            lock.unlock()
        }

        return try action()
    }

    /// Register the application's dependencies in the provided container
    private static func registerDependencies(in container: ContainerProtocol) {
        // You can call your registration functions here
        // RegisterRepositories.register(into: container)
        // RegisterUseCases.register(into: container)
        // Or use the new module API:

        container.module("Repositories") { _ in
            // Register repositories
        }

        container.module("UseCases") { _ in
            // Register use cases
        }

        container.module("Services") { _ in
            // Register services
        }
    }

    /// Create a container with mock dependencies for testing
    static func createMockContainer() -> ContainerProtocol {
        let container = createContainer()
        registerMockDependencies(in: container)
        return container
    }

    /// Register mock dependencies for testing
    private static func registerMockDependencies(in container: ContainerProtocol) {
        // Register mocks for testing
    }
}
