//
//  Factory.swift
//
//
//  Created by Boris on 7. 5. 2025..
//

import Foundation

/// Protocol for creating parameterized instances
protocol Factory {
    /// The type of object the factory produces
    associatedtype Product
    
    /// The type of parameters needed to create the product
    associatedtype Params
    
    /// Create a product instance with the given parameters
    /// - Parameter params: Parameters needed to create the instance
    /// - Returns: The created product instance
    func create(with params: Params) -> Product
}

/// Protocol for creating parameterized instances asynchronously
protocol AsyncFactory {
    /// The type of object the factory produces
    associatedtype Product
    
    /// The type of parameters needed to create the product
    associatedtype Params
    
    /// Create a product instance with the given parameters asynchronously
    /// - Parameter params: Parameters needed to create the instance
    /// - Returns: The created product instance
    func create(with params: Params) async throws -> Product
}

/// Protocol for factories with no parameters
protocol SimpleFactory {
    /// The type of object the factory produces
    associatedtype Product
    
    /// Create a product instance
    /// - Returns: The created product instance
    func create() -> Product
}

/// Protocol for async factories with no parameters
protocol AsyncSimpleFactory {
    /// The type of object the factory produces
    associatedtype Product
    
    /// Create a product instance asynchronously
    /// - Returns: The created product instance
    func create() async throws -> Product
}

/// Extension to make any factory with Void parameters conform to SimpleFactory
extension Factory where Params == Void {
    func create() -> Product {
        return create(with: ())
    }
}

/// Extension to make any async factory with Void parameters conform to AsyncSimpleFactory
extension AsyncFactory where Params == Void {
    func create() async throws -> Product {
        return try await create(with: ())
    }
}

/// Extension to the container to support resolving factories
extension ContainerProtocol {
    /// Resolve a factory from the container
    /// - Parameter name: Optional name to distinguish between multiple factories
    /// - Returns: The resolved factory
    /// - Throws: ContainerError if resolution fails
    func resolveFactory<F>(type: F.Type = F.self, name: String? = nil) async throws -> F where F: Factory, F: Sendable {
        return try await resolve(type: type, name: name)
    }
    
    /// Resolve an async factory from the container
    /// - Parameter name: Optional name to distinguish between multiple factories
    /// - Returns: The resolved factory
    /// - Throws: ContainerError if resolution fails
    func resolveAsyncFactory<F>(type: F.Type = F.self, name: String? = nil) async throws -> F where F: AsyncFactory, F: Sendable {
        return try await resolve(type: type, name: name)
    }
    
    /// Resolve a simple factory from the container
    /// - Parameter name: Optional name to distinguish between multiple factories
    /// - Returns: The resolved factory
    /// - Throws: ContainerError if resolution fails
    func resolveSimpleFactory<F>(type: F.Type = F.self, name: String? = nil) async throws -> F where F: SimpleFactory, F: Sendable {
        return try await resolve(type: type, name: name)
    }
    
    /// Resolve an async simple factory from the container
    /// - Parameter name: Optional name to distinguish between multiple factories
    /// - Returns: The resolved factory
    /// - Throws: ContainerError if resolution fails
    func resolveAsyncSimpleFactory<F>(type: F.Type = F.self, name: String? = nil) async throws -> F where F: AsyncSimpleFactory, F: Sendable {
        return try await resolve(type: type, name: name)
    }
    
    /// Create a product directly using a factory
    /// - Parameters:
    ///   - factoryType: The type of factory to use
    ///   - params: Parameters to pass to the factory
    ///   - name: Optional name to distinguish between multiple factories
    /// - Returns: The created product
    /// - Throws: ContainerError if resolution fails
    func create<F, P, T>(with factoryType: F.Type = F.self, params: P, name: String? = nil) async throws -> T
        where F: Factory, F.Product == T, F.Params == P, F: Sendable {
        let factory: F = try await resolve(type: factoryType, name: name)
        return factory.create(with: params)
    }
    
    /// Create a product directly using an async factory
    /// - Parameters:
    ///   - factoryType: The type of factory to use
    ///   - params: Parameters to pass to the factory
    ///   - name: Optional name to distinguish between multiple factories
    /// - Returns: The created product
    /// - Throws: ContainerError if resolution fails
    func createAsync<F, P, T>(with factoryType: F.Type = F.self, params: P, name: String? = nil) async throws -> T
        where F: AsyncFactory, F.Product == T, F.Params == P, F: Sendable {
        let factory: F = try await resolve(type: factoryType, name: name)
        return try await factory.create(with: params)
    }

    /// Create a product directly using a simple factory
    /// - Parameters:
    ///   - factoryType: The type of factory to use
    ///   - name: Optional name to distinguish between multiple factories
    /// - Returns: The created product
    /// - Throws: ContainerError if resolution fails
    func create<F, T>(with factoryType: F.Type = F.self, name: String? = nil) async throws -> T
        where F: SimpleFactory, F.Product == T, F: Sendable {
        let factory: F = try await resolve(type: factoryType, name: name)
        return factory.create()
    }
    
    /// Create a product directly using an async simple factory
    /// - Parameters:
    ///   - factoryType: The type of factory to use
    ///   - name: Optional name to distinguish between multiple factories
    /// - Returns: The created product
    /// - Throws: ContainerError if resolution fails
    func createAsync<F, T>(with factoryType: F.Type = F.self, name: String? = nil) async throws -> T
        where F: AsyncSimpleFactory, F.Product == T, F: Sendable {
        let factory: F = try await resolve(type: factoryType, name: name)
        return try await factory.create()
    }
}

// MARK: - Factory with type erasure

/// A type-erased factory that can be used to hide implementation details
struct AnyFactory<Product, Params>: Factory {
    private let _create: (Params) -> Product
    
    init<F: Factory>(_ factory: F) where F.Product == Product, F.Params == Params {
        self._create = factory.create(with:)
    }
    
    func create(with params: Params) -> Product {
        return _create(params)
    }
}

/// A type-erased async factory that can be used to hide implementation details
struct AnyAsyncFactory<Product, Params>: AsyncFactory {
    private let _create: (Params) async throws -> Product
    
    init<F: AsyncFactory>(_ factory: F) where F.Product == Product, F.Params == Params {
        self._create = factory.create(with:)
    }
    
    func create(with params: Params) async throws -> Product {
        return try await _create(params)
    }
}
