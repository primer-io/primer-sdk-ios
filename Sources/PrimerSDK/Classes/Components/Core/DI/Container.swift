//
//  Container.swift
//
//
//  Created by Boris on 7. 5. 2025.
//

import Foundation

/// Main implementation of the dependency injection container
public actor Container: ContainerProtocol, Sendable {
    /// Internal factory structure
    private struct FactoryRegistration {
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

        public func with(_ factory: @escaping (ContainerProtocol) async throws -> T) -> ContainerProtocol {
            Task {
                await container.registerInternal(type: type, name: name, with: policy) { resolver in
                    try await factory(resolver)
                }
            }
            return container
        }

        public func with(_ factory: @escaping (ContainerProtocol) throws -> T) -> ContainerProtocol {
            Task {
                await container.registerInternal(type: type, name: name, with: policy) { resolver in
                    try factory(resolver)
                }
            }
            return container
        }
    }

    // MARK: - Properties

    /// Map of registered factory methods using TypeKey
    private var factories: [TypeKey: FactoryRegistration] = [:]

    /// Map of strongly-held instances using TypeKey
    private var instances: [TypeKey: Any] = [:]

    /// Map of weakly-held instances
    private var weakInstances = NSMapTable<NSString, AnyObject>(
        keyOptions: [.copyIn],
        valueOptions: [.weakMemory]
    )

    /// Set used to detect circular dependencies
    private var resolutionStack: [TypeKey] = []

    /// Logger for internal operations
    private var logger: (String) -> Void = { _ in }

    // MARK: - Initialization

    public init(logger: @escaping (String) -> Void = { _ in }) {
        self.logger = logger
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
        weakInstances.removeObject(forKey: key.description as NSString)

        // Register the new factory
        factories[key] = FactoryRegistration(policy: policy) { container in
            try await factory(container)
        }

        logger("Registered \(policy) dependency: \(key)")
    }

    /// Unregister a dependency from the container
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
        weakInstances.removeObject(forKey: key.description as NSString)

        logger("Unregistered dependency: \(key)")
    }

    // MARK: - Resolution

    /// Resolve a dependency with an optional name
    public func resolve<T>(_ type: T.Type, name: String? = nil) async throws -> T {
        let key = TypeKey(type, name: name)

        // Check if the factory exists
        guard let factory = factories[key] else {
            throw ContainerError.dependencyNotRegistered(key)
        }

        // Detect circular dependencies
        if resolutionStack.contains(key) {
            throw ContainerError.circularDependency(key, path: resolutionStack + [key])
        }

        // Handle different retention policies
        switch factory.policy {
        case .transient:
            // Always create a new instance
            resolutionStack.append(key)
            defer { resolutionStack.removeLast() }

            do {
                let instance = try await factory.buildAsync(self)

                guard let typedInstance = instance as? T else {
                    throw ContainerError.typeCastFailed(key, Swift.type(of: instance))
                }

                return typedInstance
            } catch let error as ContainerError {
                throw error
            } catch {
                throw ContainerError.factoryFailed(key, underlyingError: error)
            }

        case .singleton:
            // Use existing instance or create a new one and store it strongly
            if let instance = instances[key] {
                guard let typedInstance = instance as? T else {
                    throw ContainerError.typeCastFailed(key, Swift.type(of: instance))
                }
                return typedInstance
            }

            resolutionStack.append(key)
            defer { resolutionStack.removeLast() }

            do {
                let instance = try await factory.buildAsync(self)

                guard let typedInstance = instance as? T else {
                    throw ContainerError.typeCastFailed(key, Swift.type(of: instance))
                }

                instances[key] = typedInstance
                return typedInstance
            } catch let error as ContainerError {
                throw error
            } catch {
                throw ContainerError.factoryFailed(key, underlyingError: error)
            }

        case .weak:
            // Use existing instance or create a new one and store it weakly
            let keyString = key.description as NSString
            if let instance = weakInstances.object(forKey: keyString) {
                guard let typedInstance = instance as? T else {
                    throw ContainerError.typeCastFailed(key, Swift.type(of: instance))
                }
                return typedInstance
            }

            resolutionStack.append(key)
            defer { resolutionStack.removeLast() }

            do {
                let instance = try await factory.buildAsync(self)

                guard let typedInstance = instance as? T else {
                    throw ContainerError.typeCastFailed(key, Swift.type(of: instance))
                }

                // Only store in weak references if T is a reference type
                // This prevents the warning and handles value types correctly
                if Swift.type(of: typedInstance) is AnyClass {
                    if let anyObject = typedInstance as? AnyObject {
                        weakInstances.setObject(anyObject, forKey: keyString)
                    }
                }

                return typedInstance
            } catch let error as ContainerError {
                throw error
            } catch {
                throw ContainerError.factoryFailed(key, underlyingError: error)
            }
        }
    }

    /// Resolve all dependencies conforming to a specific protocol
    public func resolveAll<T>(_ type: T.Type) async -> [T] {
        var result: [T] = []

        // Collect instances that match the type
        for (key, value) in instances {
            if let instance = value as? T {
                result.append(instance)
            }
        }

        // Collect weak instances
        let weakKeys = Array(weakInstances.keyEnumerator().allObjects)
        for keyObj in weakKeys {
            guard let key = keyObj as? NSString,
                  let instance = weakInstances.object(forKey: key),
                  let typedInstance = instance as? T else {
                continue
            }

            result.append(typedInstance)
        }

        // Collect and create instances for factories that match but aren't instantiated
        for (key, factory) in factories {
            // Skip transient factories and already collected instances
            if factory.policy == .transient {
                continue
            }

            let instance = try? await factory.buildAsync(self)
            if let typedInstance = instance as? T {
                // Only add if not already included (only check for reference types)
                if T.self is AnyClass.Type {
                    if !result.contains(where: {
                        ($0 as AnyObject) === (typedInstance as AnyObject)
                    }) {
                        result.append(typedInstance)
                    }
                } else {
                    // For value types, we can't do identity comparison, so just add
                    result.append(typedInstance)
                }
            }
        }

        return result
    }

    // MARK: - Container Lifecycle

    /// Reset all dependencies except those specified
    public func reset<T>(ignoreDependencies: [T.Type] = []) async {
        let keysToIgnore = Set(ignoreDependencies.map { TypeKey($0) })

        // Reset strong instances
        for key in instances.keys {
            if !keysToIgnore.contains(key) {
                instances.removeValue(forKey: key)
            }
        }

        // Reset weak instances
        let allWeakKeys = Array(weakInstances.keyEnumerator().allObjects)
        let weakKeysToRemove = allWeakKeys
            .compactMap { $0 as? NSString }
            .filter { keyString in
                let key = TypeKey.forType(NSObject.self, name: keyString as String)
                return !keysToIgnore.contains(key)
            }

        weakKeysToRemove.forEach { weakInstances.removeObject(forKey: $0) }

        // Reset factories
        for key in factories.keys {
            if !keysToIgnore.contains(key) {
                factories.removeValue(forKey: key)
            }
        }

        logger("Container reset (ignored \(keysToIgnore.count) dependencies)")
    }

    // MARK: - Factory Registration

    /// Register a factory for creating instances with parameters
    public nonisolated func registerFactory<F: Factory>(_ factory: F) -> Self {
        _ = register(F.self).asSingleton().with { _ in factory }
        return self
    }
}
