//
//  ContainerProtocol.swift
//
//
//  Created by Boris on 7. 5. 2025..
//

import Foundation

/// Protocol defining the core functionality of a dependency injection container
protocol ContainerProtocol: AnyObject, Sendable {
    /// Register a dependency with an optional name and specific retain policy
    /// - Parameters:
    ///   - type: The type to register
    ///   - name: Optional identifier to distinguish between multiple implementations of the same type
    ///   - policy: How the container should retain the instance
    ///   - builder: Factory closure that creates the dependency
    func register<T>(type: T.Type, name: String?, with policy: ContainerRetainPolicy, builder: @escaping (ContainerProtocol) async throws -> T)
    
    /// Resolve a dependency with an optional name
    /// - Parameters:
    ///   - type: The type to resolve
    ///   - name: Optional identifier to distinguish between multiple implementations
    /// - Returns: The resolved dependency
    /// - Throws: ContainerError if resolution fails
    func resolve<T>(type: T.Type, name: String?) async throws -> T
    
    /// Resolve all dependencies conforming to a specific protocol
    /// - Parameters:
    ///   - protocol: The protocol to match
    /// - Returns: Array of all matching dependencies
    func resolveAll<T>(conforming protocol: T.Type) async throws -> [T]
    
    /// Get or create a scope
    /// - Parameter scopeId: The scope identifier
    /// - Returns: The dependency scope
    func scope(_ scopeId: String) throws -> DependencyScope
    
    /// Create a child scope from a parent scope
    /// - Parameters:
    ///   - scopeId: The new scope identifier
    ///   - parentScopeId: The parent scope identifier
    /// - Returns: The new dependency scope
    func createScope(_ scopeId: String, parent parentScopeId: String) throws -> DependencyScope
    
    /// Release a scope and all its dependencies
    /// - Parameter scopeId: The scope identifier to release
    func releaseScope(_ scopeId: String)
    
    /// Reset all dependencies except those specified
    /// - Parameter ignoreDependencies: Types to preserve during reset
    func reset<T>(ignoreDependencies: [T.Type]) async
    
    /// Get a visualization of the dependency graph
    /// - Returns: A string representation of the dependency graph
    func dependencyGraph() async -> String
    
    /// Validate the dependency graph for issues
    /// - Returns: A list of validation issues or an empty array if no issues were found
    func validateDependencies() async -> [String]
    
    /// Register a factory for creating instances with parameters
    /// - Parameter factory: The factory to register
    func registerFactory<F: Factory>(_ factory: F) where F: Sendable
    
    /// Register a factory for creating instances with parameters asynchronously
    /// - Parameter factory: The factory to register
    func registerAsyncFactory<F: AsyncFactory>(_ factory: F) where F: Sendable
}

/// Protocol for registering dependencies in a chainable way
protocol ContainerRegistrationBuilder {
    /// Register a dependency with an optional name and specific retain policy
    /// - Parameters:
    ///   - type: The type to register
    ///   - name: Optional identifier to distinguish between multiple implementations of the same type
    ///   - policy: How the container should retain the instance
    ///   - builder: Factory closure that creates the dependency
    /// - Returns: Self for chaining
    @discardableResult
    func register<T>(type: T.Type, name: String?, with policy: ContainerRetainPolicy, builder: @escaping (ContainerProtocol) async throws -> T) -> Self
}

/// Convenience methods for ContainerProtocol
extension ContainerProtocol {
    /// Convenience method to register a dependency with default retention policy
    @discardableResult
    func register<T>(type: T.Type = T.self, name: String? = nil, builder: @escaping (ContainerProtocol) async throws -> T) -> Self where Self: ContainerRegistrationBuilder {
        return register(type: type, name: name, with: .default, builder: builder)
    }
    
    /// Convenience method to register a dependency as a singleton (strong reference)
    @discardableResult
    func singleton<T>(type: T.Type = T.self, name: String? = nil, builder: @escaping (ContainerProtocol) async throws -> T) -> Self where Self: ContainerRegistrationBuilder {
        return register(type: type, name: name, with: .strong, builder: builder)
    }
    
    /// Convenience method to register a dependency with weak reference
    @discardableResult
    func weak<T>(type: T.Type = T.self, name: String? = nil, builder: @escaping (ContainerProtocol) async throws -> T) -> Self where Self: ContainerRegistrationBuilder {
        return register(type: type, name: name, with: .weak, builder: builder)
    }
    
    /// Convenience method to register a dependency in a specific scope
    @discardableResult
    func scoped<T>(type: T.Type = T.self, name: String? = nil, in scopeId: String, builder: @escaping (ContainerProtocol) async throws -> T) -> Self where Self: ContainerRegistrationBuilder {
        return register(type: type, name: name, with: .scoped(scopeId), builder: builder)
    }
    
    /// Register an existing instance
    @discardableResult
    func instance<T>(type: T.Type = T.self, name: String? = nil, with policy: ContainerRetainPolicy = .strong, instance: T) -> Self where Self: ContainerRegistrationBuilder {
        return register(type: type, name: name, with: policy) { _ in
            return instance
        }
    }
    
    /// Convenience method to resolve a dependency with default name
    func resolve<T>(type: T.Type = T.self) async throws -> T {
        return try await resolve(type: type, name: nil)
    }
    
    /// Register a module of related dependencies
    @discardableResult
    func module(_ name: String, setup: @escaping (ContainerRegistrationBuilder) async -> Void) -> Self where Self: ContainerRegistrationBuilder {
        Task {
            await setup(self)
        }
        return self
    }
    
    /// Create a scope with optional parent
    func createScope(_ scopeId: String) throws -> DependencyScope {
        return try scope(scopeId)
    }
}

/// Protocol extension to support legacy synchronous resolution
extension ContainerProtocol {
    /// Synchronously resolve a dependency (convenience method that blocks on async resolution)
    func resolveSync<T>(type: T.Type = T.self, name: String? = nil) async throws -> T {
        // Create a task and wait for its result synchronously
        // This is less efficient but provides backward compatibility
        let result = try await Task { () -> T in
            do {
                return try await resolve(type: type, name: name)
            } catch {
                throw error
            }
        }.result.get()
        
        return result
    }
}

/// Support for registering multiple dependencies at once
extension ContainerProtocol where Self: ContainerRegistrationBuilder {
    /// Register multiple dependencies at once
    @discardableResult
    func registerAll(@ContainerRegistrationDSL _ registrations: (Self) -> Void) -> Self {
        registrations(self)
        return self
    }
}

/// Result builder for dependency registration DSL
@resultBuilder
struct ContainerRegistrationDSL {
    static func buildBlock(_ components: Void...) -> Void {}
}
