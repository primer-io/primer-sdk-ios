//
//  Container.swift
//
//
//  Created by Boris on 7. 5. 2025.
//

import Foundation

final class WeakBox<T: AnyObject> {
    weak var instance: T?
    init(_ inst: T) { self.instance = inst }
}

/// Main implementation of the dependency injection container
public actor Container: ContainerProtocol, Sendable {
    /// Internal factory structure
    struct FactoryRegistration {
        let policy: ContainerRetainPolicy
        let buildAsync: (ContainerProtocol) async throws -> Any

        init(policy: ContainerRetainPolicy, buildAsync: @escaping (ContainerProtocol) async throws -> Any) {
            self.policy = policy
            self.buildAsync = buildAsync
        }

        init(policy: ContainerRetainPolicy, buildSync: @escaping (ContainerProtocol) throws -> Any) {
            self.policy = policy
            self.buildAsync = { container in
                try buildSync(container)
            }
        }
    }

    /// Implementation of the registration builder
    public class ContainerRegistrationBuilderImpl<T>: RegistrationBuilder {
        private let container: Container
        private let type: T.Type
        private var name: String?
        private var policy: ContainerRetainPolicy = .transient

        fileprivate init(container: Container, type: T.Type) {
            self.container = container
            self.type = type
        }

        public func named(_ name: String) -> Self {
            self.name = name
            return self
        }

        public func asSingleton() -> Self {
            self.policy = .singleton
            return self
        }

        public func asWeak() -> Self {
            self.policy = .weak
            return self
        }

        public func asTransient() -> Self {
            self.policy = .transient
            return self
        }

        public func with(
            _ factory: @escaping (any ContainerProtocol) async throws -> T
        ) async throws -> Self {
            await container.registerInternal(type: type, name: name, with: policy) { resolver in
                try await factory(resolver)
            }
            return self
        }

        public func with(
            _ factory: @escaping (any ContainerProtocol) throws -> T
        ) async throws -> Self {
            await container.registerInternal(type: type, name: name, with: policy) { resolver in
                try factory(resolver)
            }
            return self
        }
    }

    // MARK: - Properties

    /// Map of registered factory methods using TypeKey
    private var factories: [TypeKey: FactoryRegistration] = [:]

    /// Map of strongly-held instances using TypeKey
    var instances: [TypeKey: Any] = [:]

    /// Map of weakly-held instances
    var weakBoxes: [TypeKey: WeakBox<AnyObject>] = [:]

    // Map each policy to its RetentionStrategy ↓
    private func strategy(for policy: ContainerRetainPolicy) -> RetentionStrategy {
        policy.makeStrategy()
    }

    /// Set used to detect circular dependencies
    private var resolutionStack: [TypeKey] = []

    /// Logger for internal operations
    private var logger: (String) -> Void = { _ in }

    // MARK: - Initialization

    public init(logger: @escaping (String) -> Void = { _ in }) {
        self.logger = logger
    }

    /// Actor-isolated setter for strong instances
    func setInstance(_ instance: Any, forKey key: TypeKey) {
        instances[key] = instance
    }

    /// Actor-isolated setter for weak boxes
    func setWeakBox(_ box: WeakBox<AnyObject>, forKey key: TypeKey) {
        weakBoxes[key] = box
    }

    // MARK: - Registration

    /// Register a dependency with the container using the fluent API
    public nonisolated func register<T>(_ type: T.Type) -> any RegistrationBuilder<T> {
        return ContainerRegistrationBuilderImpl(container: self, type: type)
    }

    /// Internal registration method
    private func registerInternal<T>(type: T.Type, name: String?, with policy: ContainerRetainPolicy, factory: @escaping (ContainerProtocol) async throws -> T) {
        let key = TypeKey(type, name: name)

        // Clean up any existing instances
        instances.removeValue(forKey: key)
        weakBoxes.removeValue(forKey: key)

        // Register the new factory
        factories[key] = FactoryRegistration(policy: policy) { container in
            try await factory(container)
        }

        logger("Registered \(policy) dependency: \(key)")
    }

    /// Unregister a dependency from the container
    @discardableResult
    public nonisolated func unregister<T>(_ type: T.Type, name: String? = nil) -> Self {
        Task {
            await unregisterInternal(type, name: name)
        }
        return self
    }

    /// Internal unregistration method
    private func unregisterInternal<T>(_ type: T.Type, name: String?) {
        let key = TypeKey(type, name: name)

        // Remove factory and instances
        factories.removeValue(forKey: key)
        instances.removeValue(forKey: key)
        weakBoxes.removeValue(forKey: key)

        logger("Unregistered dependency: \(key)")
    }

    // MARK: - Resolution

    /// Resolve a dependency with an optional name
    public func resolve<T>(_ type: T.Type, name: String? = nil) async throws -> T {
        let key = TypeKey(type, name: name)

        guard let registration = factories[key] else {
            throw ContainerError.dependencyNotRegistered(key)
        }

        // Detect circular graph
        if resolutionStack.contains(key) {
            throw ContainerError.circularDependency(key, path: resolutionStack + [key])
        }
        resolutionStack.append(key)
        defer { resolutionStack.removeLast() }

        // Delegate to the correct strategy
        let any = try await strategy(for: registration.policy)
            .instance(for: key, registration: registration, in: self)

        guard let typed = any as? T else {
            throw ContainerError.typeCastFailed(key, Swift.type(of: any))
        }
        return typed
    }

    // MARK: - Private Helpers

    /// Track and detect circular resolution
    private func pushResolution(_ key: TypeKey) throws {
        if resolutionStack.contains(key) {
            throw ContainerError.circularDependency(key, path: resolutionStack + [key])
        }
        resolutionStack.append(key)
    }

    /// Pop last resolution key
    private func popResolution() {
        resolutionStack.removeLast()
    }

    /// Cast to expected type or throw
    private func cast<T>(_ instance: Any, to key: TypeKey) throws -> T {
        guard let typed = instance as? T else {
            throw ContainerError.typeCastFailed(key, Swift.type(of: instance))
        }
        return typed
    }

    // MARK: – Resolve all

    /// Resolve all dependencies conforming to a specific protocol
    public func resolveAll<T>(_ type: T.Type) async -> [T] {
        var result: [T] = []

        // 1) Strong instances
        for value in instances.values {
            if let cast = value as? T {
                result.append(cast)
            }
        }

        // 2) Weak instances
        for box in weakBoxes.values {
            if let inst = box.instance as? T {
                result.append(inst)
            }
        }

        // 3) Non-transient factories not yet built
        for (key, registration) in factories where registration.policy != .transient {
            // skip if already in strong or weak storage
            guard !instances.keys.contains(key),
                  !weakBoxes.keys.contains(key) else {
                continue
            }

            // build it and cast if possible
            if let any = try? await strategy(for: registration.policy)
                .instance(for: key, registration: registration, in: self),
               let cast = any as? T {
                result.append(cast)
            }
        }

        return result
    }

    // MARK: - Container Lifecycle

    /// Reset all dependencies except those specified
    public func reset<T>(ignoreDependencies: [T.Type] = []) async {
        // Build a set of keys to skip during reset
        let keysToIgnore = Set(ignoreDependencies.map { TypeKey($0) })

        // Reset strong instances except the ones to ignore
        for key in instances.keys where !keysToIgnore.contains(key) {
            instances.removeValue(forKey: key)
        }

        // Weak instances
        for key in weakBoxes.keys where !keysToIgnore.contains(key) {
            weakBoxes.removeValue(forKey: key)
        }

        // Reset factories except the ones to ignore
        for key in factories.keys where !keysToIgnore.contains(key) {
            factories.removeValue(forKey: key)
        }

        logger("Container reset (ignored \(keysToIgnore.count) dependencies)")
    }
    // MARK: - Factory Registration

    /// Register a factory for creating instances with parameters
    public nonisolated func registerFactory<F: Factory>(_ factory: F) async throws -> Self {
        _ = try await register(F.self)
            .asSingleton()
            .with { _ in factory }
        return self
    }
}
