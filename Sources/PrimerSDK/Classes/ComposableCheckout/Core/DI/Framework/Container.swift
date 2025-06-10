//
//  Container.swift
//
//
//  Created by Boris on 7. 5. 2025.
//

// swiftlint:disable file_length

import Foundation

final class WeakBox<T: AnyObject> {
    weak var instance: T?
    init(_ inst: T) { self.instance = inst }
}

/// Main implementation of the dependency injection container
public actor Container: ContainerProtocol, Sendable, LogReporter {
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
            try await container.registerInternal(type: type, name: name, with: policy) { resolver in
                try await factory(resolver)
            }
            return self
        }

        public func with(
            _ factory: @escaping (any ContainerProtocol) throws -> T
        ) async throws -> Self {
            try await container.registerInternal(type: type, name: name, with: policy) { resolver in
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

    /// Set used to detect circular dependencies - using Set for O(1) lookup
    private var resolutionStack: Set<TypeKey> = []
    /// Order tracking for better error messages
    private var resolutionOrder: [TypeKey] = []

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

    /// Internal registration method with validation
    private func registerInternal<T>(
        type: T.Type,
        name: String?,
        with policy: ContainerRetainPolicy,
        factory: @escaping (ContainerProtocol) async throws -> T
    ) throws {
        let key = TypeKey(type, name: name)

        // Validate weak policy for non-class types
        if policy == .weak && !(T.self is AnyObject.Type) {
            throw ContainerError.weakUnsupported(key)
        }

        // Clean up any existing instances
        instances.removeValue(forKey: key)
        weakBoxes.removeValue(forKey: key)

        // Register the new factory
        factories[key] = FactoryRegistration(policy: policy) { container in
            try await factory(container)
        }

        logger.debug(message: "Registered \(policy) dependency: \(key)")
    }

    /// Register only if not already registered
    public nonisolated func registerIfNeeded<T>(_ type: T.Type, name: String? = nil) async -> ContainerRegistrationBuilderImpl<T>? {
        let key = TypeKey(type, name: name)
        let isRegistered = await isRegistered(key)

        guard !isRegistered else {
            logger.debug(message: "Skipping registration - already exists: \(key)")
            return nil
        }

        let builder = ContainerRegistrationBuilderImpl(container: self, type: type)
        return name != nil ? builder.named(name!) : builder
    }

    /// Check if a dependency is registered
    private func isRegistered(_ key: TypeKey) -> Bool {
        return factories[key] != nil
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

        logger.debug(message: "Unregistered dependency: \(key)")
    }

    // MARK: - Resolution

    /// Resolve a dependency with an optional name
    public func resolve<T>(_ type: T.Type, name: String? = nil) async throws -> T {
        let key = TypeKey(type, name: name)

        guard let registration = factories[key] else {
            throw ContainerError.dependencyNotRegistered(key)
        }

        // O(1) circular dependency detection
        if resolutionStack.contains(key) {
            throw ContainerError.circularDependency(key, path: resolutionOrder + [key])
        }

        // Track resolution
        resolutionStack.insert(key)
        resolutionOrder.append(key)

        defer {
            resolutionStack.remove(key)
            resolutionOrder.removeLast()
        }

        do {
            // Delegate to the correct strategy
            let instance = try await strategy(for: registration.policy)
                .instance(for: key, registration: registration, in: self)

            guard let typed = instance as? T else {
                throw ContainerError.typeCastFailed(key, expected: T.self, actual: Swift.type(of: instance))
            }

            return typed
        } catch let containerError as ContainerError {
            throw containerError
        } catch {
            throw ContainerError.factoryFailed(key, underlyingError: error)
        }
    }

    /// Synchronous resolution for SwiftUI and other sync contexts
    /// Note: This method uses a timeout to prevent indefinite blocking
    public nonisolated func resolveSync<T>(_ type: T.Type, name: String? = nil) throws -> T {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<T, Error>?

        Task {
            do {
                let resolved = try await self.resolve(type, name: name)
                result = .success(resolved)
            } catch {
                result = .failure(error)
            }
            semaphore.signal()
        }

        // Wait with a reasonable timeout (500ms)
        let timeoutResult = semaphore.wait(timeout: .now() + 0.5)

        guard timeoutResult == .success, let finalResult = result else {
            throw ContainerError.factoryFailed(
                TypeKey(type, name: name),
                underlyingError: NSError(domain: "DIContainer", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Synchronous resolution timed out"
                ])
            )
        }

        switch finalResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    /// Resolve multiple dependencies in parallel
    public func resolveBatch<T>(_ requests: [(type: T.Type, name: String?)]) async throws -> [T] {
        return try await withThrowingTaskGroup(of: (Int, T).self) { group in
            for (index, request) in requests.enumerated() {
                group.addTask {
                    let result = try await self.resolve(request.type, name: request.name)
                    return (index, result)
                }
            }

            var results: [(Int, T)] = []
            for try await result in group {
                results.append(result)
            }

            // Sort by original order
            results.sort { $0.0 < $1.0 }
            return results.map { $0.1 }
        }
    }

    // MARK: - Strategy Pattern

    /// Map each policy to its RetentionStrategy
    private func strategy(for policy: ContainerRetainPolicy) -> RetentionStrategy {
        policy.makeStrategy()
    }

    // MARK: - Resolve All

    /// Resolve all dependencies conforming to a specific protocol
    public func resolveAll<T>(_ type: T.Type) async -> [T] {
        var result: [T] = []

        // 1) Strong instances
        for value in instances.values {
            if let cast = value as? T {
                result.append(cast)
            }
        }

        // 2) Weak instances (filter out nil references)
        for box in weakBoxes.values {
            if let inst = box.instance as? T {
                result.append(inst)
            }
        }

        // 3) Non-transient factories not yet built
        for (key, registration) in factories where registration.policy != .transient {
            // Skip if already in strong or weak storage
            guard !instances.keys.contains(key),
                  !weakBoxes.keys.contains(key) else {
                continue
            }

            // Build it and cast if possible
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

        logger.debug(message: "Container reset (ignored \(keysToIgnore.count) dependencies)")
    }

    // MARK: - Memory Management

    /// Cleanup weak references that are nil
    private func cleanupWeakReferences() {
        let initialCount = weakBoxes.count
        weakBoxes = weakBoxes.compactMapValues { box in
            return box.instance != nil ? box : nil
        }
        let cleanedCount = initialCount - weakBoxes.count
        if cleanedCount > 0 {
            logger.debug(message: "Cleaned up \(cleanedCount) dead weak references")
        }
    }

    /// Periodic cleanup - call this during low-memory warnings
    public func performMaintenanceCleanup() {
        cleanupWeakReferences()
        logger.debug(message: "Performed maintenance cleanup. Active weak boxes: \(weakBoxes.count)")
    }

    // MARK: - Factory Registration

    /// Register a factory for creating instances with parameters
    public nonisolated func registerFactory<F: Factory>(_ factory: F) async throws -> Self {
        _ = try await register(F.self)
            .asSingleton()
            .with { _ in factory }
        return self
    }

    // MARK: - Diagnostics

    /// Get diagnostic information about the container state
    public func getDiagnostics() -> ContainerDiagnostics {
        cleanupWeakReferences() // Clean before reporting

        return ContainerDiagnostics(
            totalRegistrations: factories.count,
            singletonInstances: instances.count,
            weakReferences: weakBoxes.count,
            activeWeakReferences: weakBoxes.values.compactMap { $0.instance }.count,
            registeredTypes: Array(factories.keys)
        )
    }

    /// Perform health check on the container
    public func performHealthCheck() -> ContainerHealthReport {
        let diagnostics = getDiagnostics()
        var issues: [HealthIssue] = []
        var recommendations: [String] = []

        // Check for memory issues
        if diagnostics.weakReferences > 0 {
            let efficiency = Double(diagnostics.activeWeakReferences) / Double(diagnostics.weakReferences)
            if efficiency < 0.7 {
                issues.append(.memoryLeak("Low weak reference efficiency: \(String(format: "%.1f", efficiency * 100))%"))
                recommendations.append("Consider calling performMaintenanceCleanup() more frequently")
            }
        }

        // Check for orphaned registrations
        let unusedRegistrations = factories.count - diagnostics.singletonInstances
        if unusedRegistrations > diagnostics.totalRegistrations / 2 {
            issues.append(.orphanedRegistrations(unusedRegistrations))
            recommendations.append("Remove unused registrations to improve performance")
        }

        // Check circular dependencies (simplified)
        if resolutionOrder.count > 10 {
            issues.append(.deepResolutionStack("Resolution stack depth: \(resolutionOrder.count)"))
            recommendations.append("Consider breaking complex dependency chains")
        }

        return ContainerHealthReport(
            status: issues.isEmpty ? .healthy : .hasIssues,
            issues: issues,
            recommendations: recommendations,
            diagnostics: diagnostics
        )
    }
}

// swiftlint:enable file_length
