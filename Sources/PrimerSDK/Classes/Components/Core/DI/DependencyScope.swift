//
//  DependencyScope.swift
//
//
//  Created by Boris on 9. 5. 2025..
//

//
//  DependencyScope.swift
//  PrimerSDK
//
//  Created by Boris on 7. 5. 2025.
//

import Foundation

/// Protocol defining a scoped dependency container lifecycle
protocol DependencyScope: AnyObject, LogReporter {
    /// Unique identifier for the scope
    var scopeId: String { get }

    /// Set up the scope's container with dependencies
    func setupContainer() async

    /// Clean up the scope's resources
    func cleanupScope() async
}

extension DependencyScope {
    /// Register the scope with the global container
    func register() async {
        logger.info(message: "Registering scope: \(scopeId)")
        let container = DIContainer.createContainer()
        await setupContainer()
        await DIContainer.setScopedContainer(container, for: scopeId)
    }

    /// Unregister the scope from the global container
    func unregister() async {
        logger.info(message: "Unregistering scope: \(scopeId)")
        await DIContainer.removeScopedContainer(for: scopeId)
        await cleanupScope()
    }

    /// Get the scope's container
    /// - Returns: The container associated with this scope
    /// - Throws: ContainerError if the scope's container isn't available
    func getContainer() async throws -> ContainerProtocol {
        guard let container = await DIContainer.scopedContainer(for: scopeId) else {
            logger.error(message: "Missing container for scope: \(scopeId)")
            throw ContainerError.missingFactoryMethod(ContainerProtocol.self, name: "scope:\(scopeId)")
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
