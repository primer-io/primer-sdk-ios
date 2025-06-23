//
//  ContainerProtocol.swift
//
//  Created by Boris on 7. 5. 2025.
//

import Foundation

// MARK: – Registrar: registration APIs
public protocol Registrar: Sendable {
    func register<T>(_ type: T.Type) -> any RegistrationBuilder<T>
    @discardableResult
    func unregister<T>(_ type: T.Type, name: String?) -> Self
}
public extension Registrar {
    /// Convenience: no-name unregister
    @discardableResult
    func unregister<T>(_ type: T.Type) -> Self {
        unregister(type, name: nil)
    }
}

// MARK: – Resolver: resolution APIs (named with prefix DI due to conflict naming with PromisKit)
public protocol DIResolver: Sendable {
    /// Async resolution - throw if missing or failed
    func resolve<T>(_ type: T.Type, name: String?) async throws -> T

    /// Synchronous resolution - for SwiftUI and other sync contexts
    func resolveSync<T>(_ type: T.Type, name: String?) throws -> T

    /// Get all matching instances
    func resolveAll<T>(_ type: T.Type) async -> [T]
}

public extension DIResolver {
    /// Convenience: no-name async resolve
    func resolve<T>(_ type: T.Type) async throws -> T {
        try await resolve(type, name: nil)
    }

    /// Convenience: no-name sync resolve
    func resolveSync<T>(_ type: T.Type) throws -> T {
        try resolveSync(type, name: nil)
    }
}

// MARK: – LifecycleManager: container lifecycle
public protocol LifecycleManager: Sendable {
    /// Reset all except these
    func reset<T>(ignoreDependencies: [T.Type]) async
}

/// Composed container interface
public protocol ContainerProtocol: Registrar, DIResolver, LifecycleManager {}

/// Fluent builder for configuring dependency registrations
public protocol RegistrationBuilder<T> {
    associatedtype T

    /// Add a name to the registration
    func named(_ name: String) -> Self

    /// Register the dependency as a singleton (strongly retained)
    func asSingleton() -> Self

    /// Register the dependency with weak retention
    func asWeak() -> Self

    /// Register the dependency with transient (new instance each time) retention
    func asTransient() -> Self

    /// Set the async factory closure for creating the instance
    /// - Parameter factory: The async factory closure
    /// - Returns: The builder for method chaining
    func with(_ factory: @escaping (any ContainerProtocol) async throws -> T) async throws -> Self

    /// Set the sync factory closure for creating the instance
    /// - Parameter factory: The sync factory closure
    /// - Returns: The builder for method chaining
    func with(_ factory: @escaping (any ContainerProtocol) throws -> T) async throws -> Self
}
