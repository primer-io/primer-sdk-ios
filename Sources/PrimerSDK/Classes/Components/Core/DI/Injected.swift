//
//  Injected.swift
//
//
//  Created by Boris on 7. 5. 2025.
//

import Foundation

/// Result type for dependency resolution
public enum InjectionResult<T> {
    case success(T)
    case failure(ContainerError)

    /// Get the value or throw an error
    public func get() throws -> T {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    /// Get the value or return nil
    public var value: T? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
}

// MARK: - Property Wrapper Injections

/// Synchronous stub + async resolver via `$property.resolve()`
@propertyWrapper
public struct Injected<T> {
    private let name: String?

    public init(name: String? = nil) {
        self.name = name
    }

    /// ⚠️ Always fatalError if accessed synchronously
    @available(*, deprecated, message: "Use `try await $property.resolve()` instead")
    public var wrappedValue: T {
        preconditionFailure("Injected<\(T.self)> can’t be read synchronously. Use `$…resolve()`.")
    }

    /// Call this in async contexts: `let x = try await $property.resolve()`
    public func resolve() async throws -> T {
        guard let container = await DIContainer.current else {
            throw ContainerError.containerUnavailable
        }
        return try await container.resolve(T.self, name: name)
    }

    /// Enables `$property.resolve()`
    public var projectedValue: Injected<T> { self }
}

/// Optional async resolver via `$property.resolve()`, never throws
@propertyWrapper
public struct InjectedOptional<T> {
    private let name: String?

    public init(name: String? = nil) {
        self.name = name
    }

    @available(*, deprecated, message: "Use `await $property.resolve()` instead")
    public var wrappedValue: T? {
        preconditionFailure("InjectedOptional<\(T.self)> can’t be read synchronously. Use `$…resolve()`.")
    }

    /// Call this in async contexts: `let x = await $property.resolve()`
    public func resolve() async -> T? {
        guard let container = await DIContainer.current else { return nil }
        return try? await container.resolve(T.self, name: name)
    }

    public var projectedValue: InjectedOptional<T> { self }
}

/// Legacy name for clarity in UI/view‐model use; identical to `Injected`
@propertyWrapper
public struct InjectedAsync<T> {
    private let name: String?

    public init(name: String? = nil) {
        self.name = name
    }

    @available(*, deprecated, message: "Use `try await $property.resolve()` instead")
    public var wrappedValue: T {
        preconditionFailure("InjectedAsync<\(T.self)> can’t be read synchronously. Use `$…resolve()`.")
    }

    /// Call this in async contexts: `let x = try await $property.resolve()`
    public func resolve() async throws -> T {
        guard let container = await DIContainer.current else {
            throw ContainerError.containerUnavailable
        }
        return try await container.resolve(T.self, name: name)
    }

    public var projectedValue: InjectedAsync<T> { self }
}
