//
//  DependencyScope.swift
//
//
//  Created by Boris on 9. 5. 2025.
//

import Foundation

/// Protocol defining a scoped dependency container lifecycle
public protocol DependencyScope: AnyObject {
    /// Unique identifier for the scope
    var scopeId: String { get }

    /// Set up the scope's container with dependencies
    func setupContainer() async

    /// Clean up the scope's resources
    func cleanupScope() async
}

public extension DependencyScope {
    /// Register the scope with the global container
    func register() async {
        print("Registering scope: \(scopeId)")
        let container = Container()
        await setupContainer()
        await DIContainer.setScopedContainer(container, for: scopeId)
    }

    /// Unregister the scope from the global container
    func unregister() async {
        print("Unregistering scope: \(scopeId)")
        await DIContainer.removeScopedContainer(for: scopeId)
        await cleanupScope()
    }

    /// Get the scope's container
    /// - Returns: The container associated with this scope
    /// - Throws: ContainerError if the scope's container isn't available
    func getContainer() async throws -> ContainerProtocol {
        guard let container = await DIContainer.scopedContainer(for: scopeId) else {
            print("Missing container for scope: \(scopeId)")
            throw ContainerError.scopeNotFound(scopeId)
        }
        return container
    }

    /// Execute a block with the scope's container
    /// - Parameter action: The action to perform with the container
    /// - Returns: The result of the action
    /// - Throws: Any error thrown by the action or by container resolution
    func withContainer<T>(_ action: (ContainerProtocol) async throws -> T) async throws -> T {
        let container = try await getContainer()
        return try await action(container)
    }
}
