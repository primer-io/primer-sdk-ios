//
//  DependencyScope.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

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

@available(iOS 15.0, *)
public extension DependencyScope {
    /// Register the scope with the global container
    func register() async {
        let container = Container()
        await setupContainer()
        await DIContainer.setScopedContainer(container, for: scopeId)
    }

    /// Unregister the scope from the global container
    func unregister() async {
        await DIContainer.removeScopedContainer(for: scopeId)
        await cleanupScope()
    }

    /// Get the scope's container
    /// - Returns: The container associated with this scope
    /// - Throws: ContainerError if the scope's container isn't available
    func getContainer() async throws -> ContainerProtocol {
        guard let container = await DIContainer.scopedContainer(for: scopeId) else {
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
