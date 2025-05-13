//
//  AsyncFactory.swift
//
//
//  Created by Boris on 9. 5. 2025.
//

import Foundation

/// Protocol for creating parameterized instances asynchronously
public protocol AsyncFactory: Sendable {
    /// The type of object the factory produces
    associatedtype Product

    /// The type of parameters needed to create the product
    associatedtype Params

    /// Create a product instance asynchronously with the given parameters
    /// - Parameter params: Parameters needed to create the instance
    /// - Returns: The created product instance
    func create(with params: Params) async throws -> Product
}

/// Protocol for asynchronous factories with no parameters
public protocol AsyncSimpleFactory: Sendable {
    /// The type of object the factory produces
    associatedtype Product

    /// Create a product instance asynchronously
    /// - Returns: The created product instance
    func create() async throws -> Product
}

/// Extension to make any async factory with Void parameters conform to AsyncSimpleFactory
extension AsyncFactory where Params == Void {
    public func create() async throws -> Product {
        return try await create(with: ())
    }
}

/// Extension to the container to support resolving async factories
public extension ContainerProtocol {
    /// Resolve an async factory from the container
    /// - Parameter name: Optional name to distinguish between multiple factories
    /// - Returns: The resolved factory
    /// - Throws: ContainerError if resolution fails
    func resolveAsyncFactory<F>(name: String? = nil) async throws -> F where F: AsyncFactory {
        return try await resolve(F.self, name: name)
    }

    /// Create a product asynchronously directly using a factory
    /// - Parameters:
    ///   - factoryType: The type of factory to use
    ///   - params: Parameters to pass to the factory
    ///   - name: Optional name to distinguish between multiple factories
    /// - Returns: The created product
    /// - Throws: ContainerError if resolution fails
    func createAsync<F, P, T>(factoryType: F.Type, with params: P, name: String? = nil) async throws -> T
    where F: AsyncFactory, F.Product == T, F.Params == P {
        let factory: F = try await resolve(F.self, name: name)
        return try await factory.create(with: params)
    }

    /// Create a product asynchronously directly using a simple factory
    /// - Parameters:
    ///   - factoryType: The type of factory to use
    ///   - name: Optional name to distinguish between multiple factories
    /// - Returns: The created product
    /// - Throws: ContainerError if resolution fails
    func createAsync<F, T>(factoryType: F.Type, name: String? = nil) async throws -> T
    where F: AsyncSimpleFactory, F.Product == T {
        let factory: F = try await resolve(F.self, name: name)
        return try await factory.create()
    }
}
