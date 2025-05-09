//
//  Container.swift
//
//
//  Created by Boris on 7. 5. 2025..
//

import Foundation

/// Main implementation of the dependency injection container
class Container {
    /// Internal factory structure
    private struct FactoryRegistration {
        let policy: ContainerRetainPolicy
        let build: (ContainerProtocol) throws -> Any
    }

    // MARK: - Properties

    /// Thread safety lock
    private let lock = NSRecursiveLock()

    /// Map of registered factory methods
    private var factories: [String: FactoryRegistration] = [:]

    /// Map of strongly-held instances
    private var instances: [String: Any] = [:]

    /// Map of weakly-held instances
    private var weakInstances = NSMapTable<NSString, AnyObject>(
        keyOptions: [.copyIn],
        valueOptions: [.weakMemory]
    )

    /// Set used to detect circular dependencies
    private var resolutionStack: Set<String> = []

    // MARK: - Initialization

    init() {}

    // MARK: - Private Methods

    /// Generate a unique key for a type and optional name
    private func generateKey<T>(for type: T.Type, name: String?) -> String {
        let typeKey = String(reflecting: type)
        guard let name = name, !name.isEmpty else { return typeKey }
        return "\(typeKey)_\(name)"
    }
}

// MARK: - ContainerProtocol Implementation

extension Container: ContainerProtocol {
    func register<T>(name: String? = nil, with policy: ContainerRetainPolicy, builder: @escaping (ContainerProtocol) throws -> T) {
        lock.lock(); defer { lock.unlock() }

        let key = generateKey(for: T.self, name: name)

        // Clean up any existing instances
        instances[key] = nil
        weakInstances.removeObject(forKey: key as NSString)

        // Register the new factory
        factories[key] = FactoryRegistration(policy: policy, build: builder)
    }

    func resolve<T>(name: String? = nil) throws -> T! {
        lock.lock(); defer { lock.unlock() }

        let key = generateKey(for: T.self, name: name)

        // Check if the factory exists
        guard let factory = factories[key] else {
            throw ContainerError.missingFactoryMethod(T.self, name: name)
        }

        // Detect circular dependencies
        if resolutionStack.contains(key) {
            throw ContainerError.circularDependency(T.self, name: name)
        }

        // Handle different retention policies
        switch factory.policy {
        case .default:
            // Always create a new instance
            resolutionStack.insert(key)
            let instance = try factory.build(self)
            resolutionStack.remove(key)

            guard let typedInstance = instance as? T else {
                throw ContainerError.invalidFactoryReturn(expected: T.self, actual: type(of: instance))
            }

            return typedInstance

        case .strong:
            // Use existing instance or create a new one and store it strongly
            if let instance = instances[key] as? T {
                return instance
            }

            resolutionStack.insert(key)
            let instance = try factory.build(self)
            resolutionStack.remove(key)

            guard let typedInstance = instance as? T else {
                throw ContainerError.invalidFactoryReturn(expected: T.self, actual: type(of: instance))
            }

            instances[key] = typedInstance
            return typedInstance

        case .weak:
            // Use existing instance or create a new one and store it weakly
            let keyNS = key as NSString
            if let instance = weakInstances.object(forKey: keyNS) as? T {
                return instance
            }

            resolutionStack.insert(key)
            let instance = try factory.build(self)
            resolutionStack.remove(key)

            guard let typedInstance = instance as? T else {
                throw ContainerError.invalidFactoryReturn(expected: T.self, actual: type(of: instance))
            }

            if type(of: typedInstance) is AnyClass {
                let anyObject = typedInstance as AnyObject
                weakInstances.setObject(anyObject, forKey: keyNS)
            }
            return typedInstance
        }
    }

    func resolveWithType<T>(_ type: T.Type, name: String? = nil) throws -> T! {
        return try resolve(name: name) as T
    }

    func resolveAll<T>(conforming protocol: T.Type) -> [T] {
        lock.lock(); defer { lock.unlock() }

        var result: [T] = []

        // Collect strong instances
        for (_, value) in instances {
            if let instance = value as? T {
                result.append(instance)
            }
        }

        // Collect weak instances
        for (_, value) in weakInstances.dictionaryRepresentation() {
            if let instance = value as? T {
                result.append(instance)
            }
        }

        return result
    }

    func reset<T>(ignoreDependencies: [T.Type]) {
        lock.lock(); defer { lock.unlock() }

        // Create keys to ignore
        let keysToIgnore = ignoreDependencies.map { String(reflecting: $0.self) }

        // Reset strong instances
        for key in instances.keys where !keysToIgnore.contains(key) {
            instances[key] = nil
        }

        // Reset weak instances
        let weakKeysToRemove = weakInstances.keyEnumerator().allObjects
            .compactMap { $0 as? NSString }
            .filter { !keysToIgnore.contains($0 as String) }

        weakKeysToRemove.forEach { weakInstances.removeObject(forKey: $0) }
    }

    func registerFactory<F: Factory>(_ factory: F) {
        register { _ in factory }
    }
}

// swiftlint: disable identifier_name
extension Container: ContainerRegistrationBuilder {
    /// Implementation of the _register method required by ContainerRegistrationBuilder
    func _register<T>(type: T.Type, name: String?, with policy: ContainerRetainPolicy, builder: @escaping (ContainerProtocol) throws -> T) {
        register(name: name, with: policy, builder: builder)
    }
}
// swiftlint: enable identifier_name
