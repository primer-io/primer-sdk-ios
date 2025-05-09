//
//  DIContainer.swift
//
//
//  Created by Boris on 7. 5. 2025..
//

import Foundation

/// Provides global access to the current DI container with context management
final class DIContainer: LogReporter {
    /// Singleton instance
    static let shared = DIContainer()
    
    /// The current container instance
    private var _current: any ContainerProtocol
    
    /// Isolated actor for thread-safe container operations
    private actor ContainerStorage {
        var container: (any ContainerProtocol)?
        var scopedContainers: [String: (any ContainerProtocol)] = [:]
        
        init(container: (any ContainerProtocol)? = nil) {
            self.container = container
        }
        
        func getContainer() -> (any ContainerProtocol)? {
            return container
        }
        
        func setContainer(_ newContainer: (any ContainerProtocol)?) {
            container = newContainer
        }
        
        func getScopedContainer(for scopeId: String) -> (any ContainerProtocol)? {
            return scopedContainers[scopeId]
        }
        
        func setScopedContainer(_ container: (any ContainerProtocol), for scopeId: String) {
            scopedContainers[scopeId] = container
        }
        
        func removeScopedContainer(for scopeId: String) {
            scopedContainers[scopeId] = nil
        }
    }
    
    /// Thread-safe storage for containers
    private let storage: ContainerStorage
    
    /// Access to the current container
    static var current: (any ContainerProtocol)? {
        get async {
            return await shared.storage.getContainer()
        }
    }
    
    /// Private initializer for singleton
    private init() {
        let container = Container()
        self._current = container
        self.storage = ContainerStorage(container: container)
        logger.info(message: "DIContainer initialized")
    }
    
    /// Create a new container instance
    static func createContainer() -> any ContainerProtocol {
        shared.logger.debug(message: "Creating new container")
        return Container()
    }
    
    /// Set the global container instance
    static func setContainer(_ container: any ContainerProtocol) async {
        shared.logger.info(message: "Setting global container")
        await shared.storage.setContainer(container)
    }
    
    /// Set up a container with the application's dependencies
    static func setupMainContainer() async {
        shared.logger.info(message: "Setting up main container")
        let container = createContainer()
        await registerDependencies(in: container)
        await setContainer(container)
    }
    
    /// Execute a block with a temporary container and restore the previous one afterward
    /// Useful for isolated testing contexts
    ///
    /// - Parameters:
    ///   - container: The container to use during the execution of the action
    ///   - action: The closure to execute with the temporary container
    /// - Returns: The result of the action
    /// - Throws: Any error thrown by the action
    @discardableResult
    static func withContainer<T>(_ container: any ContainerProtocol, perform action: () async throws -> T) async rethrows -> T {
        shared.logger.debug(message: "Switching to temporary container")
        let previous = await shared.storage.getContainer()
        await shared.storage.setContainer(container)
        
        defer {
            Task {
                shared.logger.debug(message: "Restoring previous container")
                await shared.storage.setContainer(previous)
            }
        }
        
        return try await action()
    }
    
    /// Add a scoped container
    static func setScopedContainer(_ container: any ContainerProtocol, for scopeId: String) async {
        shared.logger.info(message: "Setting scoped container for: \(scopeId)")
        await shared.storage.setScopedContainer(container, for: scopeId)
    }
    
    /// Get a scoped container
    static func scopedContainer(for scopeId: String) async -> (any ContainerProtocol)? {
        return await shared.storage.getScopedContainer(for: scopeId)
    }
    
    /// Remove a scoped container
    static func removeScopedContainer(for scopeId: String) async {
        shared.logger.info(message: "Removing scoped container for: \(scopeId)")
        await shared.storage.removeScopedContainer(for: scopeId)
    }
    
    /// Register the application's dependencies in the provided container
    private static func registerDependencies(in container: any ContainerProtocol) async {
        guard let container = container as? ContainerRegistrationBuilder else {
            shared.logger.error(message: "Container does not conform to ContainerRegistrationBuilder")
            return
        }
        
        shared.logger.info(message: "Registering application dependencies")
        
        // Register the container itself
        container.singleton(type: ContainerProtocol.self) { container in
            return container
        }
        
        // Register logger
        container.singleton(type: PrimerLogger.self) { _ in
            return PrimerLogging.shared.logger
        }
        
        // Register modules
        await container.module("Repositories") { container in
            // Register repositories
            shared.logger.debug(message: "Registering repositories")
        }
        
        await container.module("UseCases") { container in
            // Register use cases
            shared.logger.debug(message: "Registering use cases")
        }
        
        await container.module("Services") { container in
            // Register services
            shared.logger.debug(message: "Registering services")
        }
    }
    
    /// Create a container with mock dependencies for testing
    static func createMockContainer() async -> any ContainerProtocol {
        shared.logger.info(message: "Creating mock container")
        let container = createContainer()
        await registerMockDependencies(in: container)
        return container
    }
    
    /// Register mock dependencies for testing
    private static func registerMockDependencies(in container: any ContainerProtocol) async {
        guard let container = container as? ContainerRegistrationBuilder else {
            shared.logger.error(message: "Container does not conform to ContainerRegistrationBuilder")
            return
        }
        
        shared.logger.info(message: "Registering mock dependencies")
        
        // Register mocks for testing
        await container.module("MockRepositories") { container in
            // Register mock repositories
            shared.logger.debug(message: "Registering mock repositories")
        }
        
        await container.module("MockUseCases") { container in
            // Register mock use cases
            shared.logger.debug(message: "Registering mock use cases")
        }
        
        await container.module("MockServices") { container in
            // Register mock services
            shared.logger.debug(message: "Registering mock services")
        }
    }
}

/// Convenience extension for backward compatibility
extension DIContainer {
    /// Get the current container synchronously (may block)
    static var currentSync: (any ContainerProtocol)? {
        get {
            let container = Task {
                await current
            }
            return try? container.result.get()
        }
        set {
            Task {
                if let newValue = newValue {
                    await setContainer(newValue)
                } else {
                    await setContainer(nil)
                }
            }
        }
    }
    
    /// Set up a container with the application's dependencies synchronously
    static func setupMainContainerSync() {
        Task {
            await setupMainContainer()
        }
    }
}
