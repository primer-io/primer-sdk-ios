//
//  Container.swift
//
//
//  Created by Boris on 7. 5. 2025..
//

import Foundation

/// Main implementation of the dependency injection container as an actor for thread safety
actor Container: LogReporter {
    /// Internal factory structure
    private struct FactoryRegistration {
        let policy: ContainerRetainPolicy
        let build: (ContainerProtocol) async throws -> Any
    }
    
    // MARK: - Properties
    
    /// Map of registered factory methods
    private var factories: [TypeKey: FactoryRegistration] = [:]
    
    /// Map of strongly-held instances
    private var instances: [TypeKey: Any] = [:]
    
    /// Map of scoped instances
    private var scopedInstances: [String: [TypeKey: Any]] = [:]
    
    /// Set used to detect circular dependencies
    private var resolutionStack: Set<TypeKey> = []
    
    /// Resolution path for better error reporting
    private var resolutionPath: [String] = []
    
    /// Available scopes
    private var scopes: [String: DependencyScope] = [
        DependencyScope.application.id: DependencyScope.application
    ]
    
    /// Flag to indicate if the container has been terminated
    private var isTerminated = false
    
    // MARK: - Initialization
    
    init() {
        logger.info(message: "Container initialized")
    }
    
    deinit {
        logger.debug(message: "Container deinitializing")
    }
    
    // MARK: - Helper Methods
    
    /// Create a type key for a specific type and optional name
    private func typeKey<T>(for type: T.Type, name: String?) -> TypeKey {
        return TypeKey(type, name: name)
    }
    
    /// Check if the container has been terminated
    private func checkTermination() throws {
        if isTerminated {
            logger.error(message: "Container has been terminated")
            throw ContainerError.containerTerminated
        }
    }
    
    /// Terminate the container and release all resources
    func terminate() {
        logger.info(message: "Container terminating")
        isTerminated = true
        factories.removeAll()
        instances.removeAll()
        scopedInstances.removeAll()
        scopes.removeAll()
    }
}

// MARK: - ContainerProtocol Implementation

extension Container: ContainerProtocol {
    nonisolated func register<T>(type: T.Type, name: String? = nil, with policy: ContainerRetainPolicy, builder: @escaping (ContainerProtocol) async throws -> T) {
        Task {
            await _register(type: type, name: name, with: policy, builder: builder)
        }
    }
    
    private func _register<T>(type: T.Type, name: String? = nil, with policy: ContainerRetainPolicy, builder: @escaping (ContainerProtocol) async throws -> T) {
        // Create a key for the registration
        let key = typeKey(for: type, name: name)
        
        logger.debug(message: "Registering dependency: \(type) with name: \(name ?? "nil") and policy: \(policy)")
        
        // Clean up any existing instances for this key
        instances[key] = nil
        
        // Clean up any scoped instances if this is a scoped registration
        if case .scoped(let scopeId) = policy {
            scopedInstances[scopeId]?[key] = nil
        }
        
        // Register the new factory
        factories[key] = FactoryRegistration(policy: policy, build: builder)
    }
    
    func resolve<T>(type: T.Type, name: String? = nil) async throws -> T {
        try checkTermination()
        
        let key = typeKey(for: type, name: name)
        
        // Check if the factory exists
        guard let factory = factories[key] else {
            logger.error(message: "Missing factory method for type: \(type) with name: \(name ?? "nil")")
            throw ContainerError.missingFactoryMethod(type, name: name)
        }
        
        // Detect circular dependencies
        if resolutionStack.contains(key) {
            logger.error(message: "Circular dependency detected while resolving: \(type) with name: \(name ?? "nil")")
            throw ContainerError.circularDependency(type, name: name, resolutionPath: resolutionPath)
        }
        
        logger.debug(message: "Resolving dependency: \(type) with name: \(name ?? "nil")")
        
        // Handle different retention policies
        switch factory.policy {
        case .default:
            // Always create a new instance
            resolutionStack.insert(key)
            resolutionPath.append(key.description)
            
            defer {
                resolutionStack.remove(key)
                resolutionPath.removeLast()
            }
            
            let instance = try await factory.build(self)
            
            guard let typedInstance = instance as? T else {
                logger.error(message: "Factory returned invalid type: expected \(T.self), got \(type(of: instance))")
                throw ContainerError.invalidFactoryReturn(expected: T.self, actual: type(of: instance))
            }
            
            return typedInstance
            
        case .strong:
            // Use existing instance or create a new one and store it strongly
            if let instance = instances[key] as? T {
                logger.debug(message: "Returning existing strong instance for: \(type) with name: \(name ?? "nil")")
                return instance
            }
            
            resolutionStack.insert(key)
            resolutionPath.append(key.description)
            
            defer {
                resolutionStack.remove(key)
                resolutionPath.removeLast()
            }
            
            let instance = try await factory.build(self)
            
            guard let typedInstance = instance as? T else {
                logger.error(message: "Factory returned invalid type: expected \(T.self), got \(type(of: instance))")
                throw ContainerError.invalidFactoryReturn(expected: T.self, actual: type(of: instance))
            }
            
            logger.debug(message: "Storing new strong instance for: \(type) with name: \(name ?? "nil")")
            instances[key] = typedInstance
            return typedInstance
            
        case .weak:
            // Use existing instance or create a new one and store it weakly
            // Note: We'll use a WeakBox wrapper to store weak references
            if let instance = instances[key] as? WeakBox, let value = instance.value as? T {
                logger.debug(message: "Returning existing weak instance for: \(type) with name: \(name ?? "nil")")
                return value
            }
            
            resolutionStack.insert(key)
            resolutionPath.append(key.description)
            
            defer {
                resolutionStack.remove(key)
                resolutionPath.removeLast()
            }
            
            let instance = try await factory.build(self)
            
            guard let typedInstance = instance as? T else {
                logger.error(message: "Factory returned invalid type: expected \(T.self), got \(type(of: instance))")
                throw ContainerError.invalidFactoryReturn(expected: T.self, actual: type(of: instance))
            }
            
            // Only store reference types weakly
            if let objectInstance = typedInstance as AnyObject {
                logger.debug(message: "Storing new weak instance for: \(type) with name: \(name ?? "nil")")
                instances[key] = WeakBox(objectInstance)
            }
            
            return typedInstance
            
        case .scoped(let scopeId):
            // Check if the scope exists
            guard scopes[scopeId] != nil else {
                logger.error(message: "Scope not found: \(scopeId) for type: \(type) with name: \(name ?? "nil")")
                throw ContainerError.scopeNotFound(scopeId)
            }
            
            // Initialize the scope's instance storage if needed
            if scopedInstances[scopeId] == nil {
                scopedInstances[scopeId] = [:]
            }
            
            // Use existing instance from the scope or create a new one
            if let instance = scopedInstances[scopeId]?[key] as? T {
                logger.debug(message: "Returning existing scoped instance for: \(type) with name: \(name ?? "nil") in scope: \(scopeId)")
                return instance
            }
            
            resolutionStack.insert(key)
            resolutionPath.append(key.description)
            
            defer {
                resolutionStack.remove(key)
                resolutionPath.removeLast()
            }
            
            let instance = try await factory.build(self)
            
            guard let typedInstance = instance as? T else {
                logger.error(message: "Factory returned invalid type: expected \(T.self), got \(type(of: instance))")
                throw ContainerError.invalidFactoryReturn(expected: T.self, actual: type(of: instance))
            }
            
            logger.debug(message: "Storing new scoped instance for: \(type) with name: \(name ?? "nil") in scope: \(scopeId)")
            scopedInstances[scopeId]?[key] = typedInstance
            return typedInstance
        }
    }
    
    func resolveAll<T>(conforming protocol: T.Type) async throws -> [T] {
        try checkTermination()
        
        logger.debug(message: "Resolving all dependencies conforming to: \(T.self)")
        
        var result: [T] = []
        
        // Function to add instances to result if they conform to the protocol
        func addMatchingInstances(_ instances: [Any]) {
            for instance in instances {
                if let matchingInstance = instance as? T {
                    result.append(matchingInstance)
                } else if let weakBox = instance as? WeakBox, let value = weakBox.value as? T {
                    result.append(value)
                }
            }
        }
        
        // Collect global instances
        addMatchingInstances(Array(instances.values))
        
        // Collect scoped instances
        for (_, scopeInstances) in scopedInstances {
            addMatchingInstances(Array(scopeInstances.values))
        }
        
        logger.debug(message: "Found \(result.count) dependencies conforming to: \(T.self)")
        return result
    }
    
    nonisolated func scope(_ scopeId: String) throws -> DependencyScope {
        return Task { 
            try await _scope(scopeId)
        }.result.get()
    }
    
    private func _scope(_ scopeId: String) throws -> DependencyScope {
        try checkTermination()
        
        if let scope = scopes[scopeId] {
            return scope
        }
        
        logger.info(message: "Creating new scope: \(scopeId)")
        let newScope = DependencyScope(id: scopeId, parent: DependencyScope.application)
        scopes[scopeId] = newScope
        return newScope
    }
    
    nonisolated func createScope(_ scopeId: String, parent parentScopeId: String) throws -> DependencyScope {
        return Task {
            try await _createScope(scopeId, parent: parentScopeId)
        }.result.get()
    }
    
    private func _createScope(_ scopeId: String, parent parentScopeId: String) throws -> DependencyScope {
        try checkTermination()
        
        guard let parentScope = scopes[parentScopeId] else {
            logger.error(message: "Parent scope not found: \(parentScopeId)")
            throw ContainerError.scopeNotFound(parentScopeId)
        }
        
        logger.info(message: "Creating new scope: \(scopeId) with parent: \(parentScopeId)")
        let newScope = DependencyScope(id: scopeId, parent: parentScope)
        scopes[scopeId] = newScope
        return newScope
    }
    
    nonisolated func releaseScope(_ scopeId: String) {
        Task {
            await _releaseScope(scopeId)
        }
    }
    
    private func _releaseScope(_ scopeId: String) {
        // Don't release the application scope
        guard scopeId != DependencyScope.application.id else {
            return
        }
        
        scopes[scopeId] = nil
        scopedInstances[scopeId] = nil
    }
    
    func reset<T>(ignoreDependencies: [T.Type] = []) async {
        try? checkTermination()
        
        logger.info(message: "Resetting container except for specified dependencies")
        
        // Create keys to ignore
        let keysToIgnore = ignoreDependencies.map { typeKey(for: $0, name: nil) }
        
        // Reset strong instances
        for key in instances.keys where !keysToIgnore.contains(key) {
            instances[key] = nil
        }
        
        // Reset scoped instances (except application scope)
        for scopeId in scopedInstances.keys where scopeId != DependencyScope.application.id {
            scopedInstances[scopeId] = nil
        }
    }
    
    func dependencyGraph() async -> String {
        var graph = "Dependency Graph:\n"
        
        graph += "\nRegistered Types:\n"
        for (key, registration) in factories {
            graph += "- \(key.description): \(registration.policy)\n"
        }
        
        graph += "\nInstantiated Singletons:\n"
        for key in instances.keys {
            graph += "- \(key.description)\n"
        }
        
        graph += "\nScoped Instances:\n"
        for (scopeId, instances) in scopedInstances {
            graph += "- Scope: \(scopeId)\n"
            for key in instances.keys {
                graph += "  - \(key.description)\n"
            }
        }
        
        return graph
    }
    
    func validateDependencies() async -> [String] {
        var issues: [String] = []
        
        for (key, registration) in factories {
            switch registration.policy {
            case .scoped(let scopeId):
                if scopes[scopeId] == nil {
                    issues.append("Dependency \(key.description) is registered in non-existent scope: \(scopeId)")
                }
            default:
                break
            }
        }
        
        return issues
    }
    
    nonisolated func registerFactory<F: Factory>(_ factory: F) where F: Sendable {
        Task {
            await _registerFactory(factory)
        }
    }
    
    private func _registerFactory<F: Factory>(_ factory: F) where F: Sendable {
        logger.debug(message: "Registering factory: \(F.self)")
        _register(type: F.self) { _ in
            return factory
        }
    }
    
    nonisolated func registerAsyncFactory<F: AsyncFactory>(_ factory: F) where F: Sendable {
        Task {
            await _registerAsyncFactory(factory)
        }
    }
    
    private func _registerAsyncFactory<F: AsyncFactory>(_ factory: F) where F: Sendable {
        logger.debug(message: "Registering async factory: \(F.self)")
        _register(type: F.self) { _ in
            return factory
        }
    }
}

// MARK: - ContainerRegistrationBuilder Implementation

extension Container: ContainerRegistrationBuilder {
    @discardableResult
    nonisolated func register<T>(type: T.Type, name: String?, with policy: ContainerRetainPolicy, builder: @escaping (ContainerProtocol) async throws -> T) -> Self {
        Task {
            await _register(type: type, name: name, with: policy, builder: builder)
        }
        return self
    }
}

// MARK: - WeakBox for weak references

/// Wrapper class for holding weak references
private class WeakBox: Sendable {
    weak var value: AnyObject?
    
    init(_ value: AnyObject) {
        self.value = value
    }
}
