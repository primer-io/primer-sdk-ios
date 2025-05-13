//
//  Factory.swift
//
//
//  Created by Boris on 7. 5. 2025.
//

import Foundation

/// Protocol for creating parameterized instances
public protocol Factory: Sendable {
    /// The type of object the factory produces
    associatedtype Product

    /// The type of parameters needed to create the product
    associatedtype Params

    /// Create a product instance with the given parameters
    /// - Parameter params: Parameters needed to create the instance
    /// - Returns: The created product instance
    func create(with params: Params) -> Product
}

/// Protocol for factories with no parameters
public protocol SimpleFactory: Sendable {
    /// The type of object the factory produces
    associatedtype Product

    /// Create a product instance
    /// - Returns: The created product instance
    func create() -> Product
}

/// Extension to make any factory with Void parameters conform to SimpleFactory
extension Factory where Params == Void {
    public func create() -> Product {
        return create(with: ())
    }
}

/// Extension to the container to support resolving factories
public extension ContainerProtocol {
    /// Resolve a factory from the container
    /// - Parameter name: Optional name to distinguish between multiple factories
    /// - Returns: The resolved factory
    /// - Throws: ContainerError if resolution fails
    func resolveFactory<F>(name: String? = nil) async throws -> F where F: Factory {
        return try await resolve(F.self, name: name)
    }

    /// Create a product directly using a factory
    /// - Parameters:
    ///   - factoryType: The type of factory to use
    ///   - params: Parameters to pass to the factory
    ///   - name: Optional name to distinguish between multiple factories
    /// - Returns: The created product
    /// - Throws: ContainerError if resolution fails
    func create<F, P, T>(factoryType: F.Type, with params: P, name: String? = nil) async throws -> T
    where F: Factory, F.Product == T, F.Params == P {
        let factory: F = try await resolve(F.self, name: name)
        return factory.create(with: params)
    }

    /// Create a product directly using a simple factory
    /// - Parameters:
    ///   - factoryType: The type of factory to use
    ///   - name: Optional name to distinguish between multiple factories
    /// - Returns: The created product
    /// - Throws: ContainerError if resolution fails
    func create<F, T>(factoryType: F.Type, name: String? = nil) async throws -> T
    where F: SimpleFactory, F.Product == T {
        let factory: F = try await resolve(F.self, name: name)
        return factory.create()
    }
}
