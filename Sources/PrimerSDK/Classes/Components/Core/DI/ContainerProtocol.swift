//
//  ContainerProtocol.swift
//
//
//  Created by Boris on 7. 5. 2025..
//

import Foundation

/// Protocol defining the core functionality of a dependency injection container
protocol ContainerProtocol {
    /// Register a dependency with an optional name and specific retain policy
    /// - Parameters:
    ///   - name: Optional identifier to distinguish between multiple implementations of the same type
    ///   - policy: How the container should retain the instance
    ///   - builder: Factory closure that creates the dependency
    func register<T>(name: String?, with policy: ContainerRetainPolicy, builder: @escaping (ContainerProtocol) throws -> T)

    /// Resolve a dependency with an optional name
    /// - Parameter name: Optional identifier to distinguish between multiple implementations
    /// - Returns: The resolved dependency
    /// - Throws: ContainerError if resolution fails
    func resolve<T>(name: String?) throws -> T!

    /// Resolve a dependency with explicit type
    /// - Parameters:
    ///   - type: The type to resolve
    ///   - name: Optional identifier to distinguish between multiple implementations
    /// - Returns: The resolved dependency
    /// - Throws: ContainerError if resolution fails
    func resolveWithType<T>(_ type: T.Type, name: String?) throws -> T!

    /// Resolve all dependencies conforming to a specific protocol
    /// - Parameters:
    ///   - protocol: The protocol to match
    /// - Returns: Array of all matching dependencies
    func resolveAll<T>(conforming protocol: T.Type) -> [T]

    /// Reset all dependencies except those specified
    /// - Parameter ignoreDependencies: Types to preserve during reset
    func reset<T>(ignoreDependencies: [T.Type])

    /// Register a factory for creating instances with parameters
    /// - Parameter factory: The factory to register
    func registerFactory<F: Factory>(_ factory: F)
}

extension ContainerProtocol {
    /// Convenience method to register a dependency with default retention policy
    func register<T>(name: String? = nil, builder: @escaping (ContainerProtocol) throws -> T) {
        register(name: name, with: .default, builder: builder)
    }

    /// Convenience method to register a dependency with default name
    func register<T>(with policy: ContainerRetainPolicy, builder: @escaping (ContainerProtocol) throws -> T) {
        register(name: nil, with: policy, builder: builder)
    }

    /// Convenience method to resolve a dependency with default name
    func resolve<T>() throws -> T! {
        try resolve(name: nil)
    }

    /// Convenience method to resolve a dependency with explicit type and default name
    func resolveWithType<T>(_ type: T.Type) throws -> T! {
        try resolveWithType(type, name: nil)
    }

    /// Register a module of related dependencies
    func module(_ name: String, setup: (ContainerProtocol) -> Void) {
        setup(self)
    }
}
