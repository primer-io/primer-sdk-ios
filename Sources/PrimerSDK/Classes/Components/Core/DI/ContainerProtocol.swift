//
//  ContainerProtocol.swift
//
//
//  Created by Boris on 7. 5. 2025.
//

import Foundation

/// Protocol defining the core functionality of a dependency injection container
public protocol ContainerProtocol: Sendable {
    // MARK: - Registration API

    /// Register a dependency with the container using the new fluent API
    /// - Parameter type: The type to register
    /// - Returns: A registration builder for configuring the registration
    func register<T>(_ type: T.Type) -> any RegistrationBuilder<T>

    /// Unregister a dependency from the container
    /// - Parameters:
    ///   - type: The type to unregister
    ///   - name: Optional identifier to distinguish between multiple implementations
    /// - Returns: The container instance for method chaining
    func unregister<T>(_ type: T.Type, name: String?) -> Self

    // MARK: - Resolution API

    /// Resolve a dependency with an optional name
    /// - Parameters:
    ///   - type: The type to resolve
    ///   - name: Optional identifier to distinguish between multiple implementations
    /// - Returns: The resolved dependency
    /// - Throws: ContainerError if resolution fails
    func resolve<T>(_ type: T.Type, name: String?) async throws -> T

    /// Resolve all dependencies conforming to a specific protocol
    /// - Parameter type: The protocol type to match
    /// - Returns: Array of all matching dependencies
    func resolveAll<T>(_ type: T.Type) async -> [T]

    // MARK: - Container Lifecycle

    /// Reset all dependencies except those specified
    /// - Parameter ignoreDependencies: Types to preserve during reset
    func reset<T>(ignoreDependencies: [T.Type]) async
}

/// Fluent builder for configuring dependency registrations
public protocol RegistrationBuilder<T> {
    associatedtype T

    /// Add a name to the registration
    /// - Parameter name: The name to identify this registration
    /// - Returns: The builder for method chaining
    func named(_ name: String) -> Self

    /// Register the dependency as a singleton (strongly retained)
    /// - Returns: The builder for method chaining
    func asSingleton() -> Self

    /// Register the dependency with weak retention
    /// - Returns: The builder for method chaining
    func asWeak() -> Self

    /// Register the dependency with transient (new instance each time) retention
    /// - Returns: The builder for method chaining
    func asTransient() -> Self

    /// Set the factory closure for creating the instance
    /// - Parameter factory: The factory closure
    /// - Returns: The container for method chaining
    func with(_ factory: @escaping (any ContainerProtocol) async throws -> T) -> any ContainerProtocol

    /// Set a synchronous factory closure for creating the instance
    /// - Parameter factory: The synchronous factory closure
    /// - Returns: The container for method chaining
    func with(_ factory: @escaping (any ContainerProtocol) throws -> T) -> any ContainerProtocol
}
