//
//  Factory.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Modern factory that handles both sync and async creation
public protocol Factory<Product, Params>: Sendable {
    associatedtype Product
    associatedtype Params = Void

    func create(with params: Params) async throws -> Product
}

/// Protocol marker for factories that are inherently synchronous
/// This allows for performance optimizations when we know the factory is sync
public protocol SynchronousFactory<Product, Params>: Factory {
    /// Synchronous creation method - implement this for purely sync factories
    func createSync(with params: Params) throws -> Product
}

public extension SynchronousFactory {
    func create(with params: Params) async throws -> Product {
        // For sync factories, just call the sync method
        try createSync(with: params)
    }
}

public extension Factory where Params == Void {
    func create() async throws -> Product {
        try await create(with: ())
    }
}

public extension SynchronousFactory where Params == Void {
    func createSync() throws -> Product {
        try createSync(with: ())
    }
}

/// Enhanced container extension for modern factories
public extension ContainerProtocol {
    /// Register a factory instance as singleton
    /// - Parameters:
    ///   - factory: The factory instance to register
    ///   - name: Optional name for multiple registrations of the same type
    /// - Returns: Self for method chaining
    @discardableResult
    func registerFactory<F: Factory>(
        _ factory: F,
        name: String? = nil
    ) async throws -> Self {
        if let name {
            _ = try await register(F.self)
                .named(name)
                .asSingleton()
                .with { _ in factory }
        } else {
            _ = try await register(F.self)
                .asSingleton()
                .with { _ in factory }
        }
        return self
    }

    /// Register a factory instance with a specific retention policy
    /// - Parameters:
    ///   - factory: The factory instance to register
    ///   - policy: Retention policy for the factory
    ///   - name: Optional name for multiple registrations
    /// - Returns: Self for method chaining
    @discardableResult
    func registerFactory<F: Factory>(
        _ factory: F,
        policy: ContainerRetainPolicy,
        name: String? = nil
    ) async throws -> Self {
        let builder = register(F.self)
        let namedBuilder = name != nil ? builder.named(name!) : builder

        let policyBuilder = switch policy {
        case .singleton: namedBuilder.asSingleton()
        case .transient: namedBuilder.asTransient()
        case .weak:      namedBuilder.asWeak()
        }

        _ = try await policyBuilder.with { _ in factory }
        return self
    }

    /// Register a factory‐creation closure with retention policy
    /// - Parameters:
    ///   - factoryType: The factory type to register
    ///   - policy: Retention policy (defaults to singleton)
    ///   - name: Optional name for multiple registrations
    ///   - factory: Async-throwing closure that creates the factory instance
    /// - Returns: Self for method chaining
    @discardableResult
    func registerFactory<F: Factory>(
        _ factoryType: F.Type,
        policy: ContainerRetainPolicy = .singleton,
        name: String? = nil,
        factory: @escaping (ContainerProtocol) async throws -> F
    ) async throws -> Self {
        let builder = register(F.self)
        let namedBuilder = name != nil ? builder.named(name!) : builder

        let policyBuilder = switch policy {
        case .singleton: namedBuilder.asSingleton()
        case .transient: namedBuilder.asTransient()
        case .weak:      namedBuilder.asWeak()
        }

        _ = try await policyBuilder.with(factory)
        return self
    }
}
