//
//  ContainerProtocol.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// MARK: – Registrar: registration APIs
public protocol Registrar: Sendable {
    func register<T>(_ type: T.Type) -> any RegistrationBuilder<T>
    @discardableResult
    func unregister<T>(_ type: T.Type, name: String?) async -> Self
}
public extension Registrar {
    @discardableResult
    func unregister<T>(_ type: T.Type) async -> Self {
        await unregister(type, name: nil)
    }
}

// MARK: – Resolver: resolution APIs (named with prefix DI due to conflict naming with PromisKit)
public protocol DIResolver: Sendable {
    /// Async resolution - throw if missing or failed
    func resolve<T>(_ type: T.Type, name: String?) async throws -> T

    /// Synchronous resolution - for SwiftUI and other sync contexts
    func resolveSync<T>(_ type: T.Type, name: String?) throws -> T

    func resolveAll<T>(_ type: T.Type) async -> [T]
}

public extension DIResolver {
    func resolve<T>(_ type: T.Type) async throws -> T {
        try await resolve(type, name: nil)
    }

    func resolveSync<T>(_ type: T.Type) throws -> T {
        try resolveSync(type, name: nil)
    }
}

// MARK: – LifecycleManager: container lifecycle
public protocol LifecycleManager: Sendable {
    func reset<T>(ignoreDependencies: [T.Type]) async
}

public protocol ContainerProtocol: Registrar, DIResolver, LifecycleManager {}

/// Fluent builder for configuring dependency registrations
public protocol RegistrationBuilder<T> {
    associatedtype T

    func named(_ name: String) -> Self
    /// Strongly retained singleton
    func asSingleton() -> Self
    func asWeak() -> Self
    /// New instance each time
    func asTransient() -> Self
    func with(_ factory: @escaping (any ContainerProtocol) async throws -> T) async throws -> Self
    func with(_ factory: @escaping (any ContainerProtocol) throws -> T) async throws -> Self
}
