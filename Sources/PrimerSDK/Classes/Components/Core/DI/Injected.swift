//
//  Injected.swift
//
//
//  Created by Boris on 7. 5. 2025..
//

import Foundation

/// Property wrapper for automatically injecting dependencies
@propertyWrapper
struct Injected<T> {
    /// Error handling strategy for failed injections
    enum ErrorStrategy {
        /// Crash the application immediately with fatalError
        case crash
        /// Return nil for failed resolutions (only valid for optional types)
        case returnNil
        /// Use a default value if resolution fails
        case useDefault(T)
        /// Log the error and crash (useful for debugging)
        case logAndCrash
    }
    
    // MARK: - Properties
    
    /// Optional name to distinguish between multiple implementations
    private let name: String?
    
    /// Error handling strategy
    private let errorStrategy: ErrorStrategy
    
    /// Whether to lazily initialize the dependency
    private let lazyInit: Bool
    
    /// Storage for the resolved dependency
    private var storage: T?
    
    /// Task for asynchronous resolution
    private var resolutionTask: Task<T, Error>?
    
    /// Flag to indicate whether async resolution has been initialized
    private var asyncInitialized = false
    
    // MARK: - Initialization
    
    /// Initialize the property wrapper
    /// - Parameters:
    ///   - name: Optional name to distinguish between multiple implementations
    ///   - lazy: Whether to lazily initialize the dependency
    ///   - errorStrategy: Strategy for handling resolution errors
    init(name: String? = nil, lazy: Bool = true, errorStrategy: ErrorStrategy = .crash) {
        self.name = name
        self.lazyInit = lazy
        self.errorStrategy = errorStrategy
        
        if !lazyInit {
            initializeAsync()
        }
    }
    
    // MARK: - Property Wrapper
    
    /// The wrapped value, which resolves the dependency on first access
    var wrappedValue: T {
        mutating get {
            // Return cached value if available
            if let value = storage {
                return value
            }
            
            // Initialize async resolution if needed
            if !asyncInitialized {
                initializeAsync()
            }
            
            // Wait for resolution task to complete
            guard let task = resolutionTask else {
                return handleError("Resolution task not initialized")
            }
            
            do {
                let result = try Task.detached {
                    try await task.value
                }.result.get()
                
                storage = result
                return result
            } catch {
                return handleError(error.localizedDescription)
            }
        }
    }
    
    /// Provides access to the projectedValue (self)
    var projectedValue: Self {
        return self
    }
    
    // MARK: - Helper Methods
    
    /// Initialize the asynchronous resolution task
    private mutating func initializeAsync() {
        let resolutionName = name
        let logger = PrimerLogging.shared.logger
        
        resolutionTask = Task { () -> T in
            logger.debug(message: "Starting async resolution for type \(T.self) with name: \(resolutionName ?? "nil")")
            
            guard let container = await DIContainer.current else {
                logger.error(message: "No DI container available")
                throw ContainerError.containerTerminated
            }
            
            do {
                let resolved = try await container.resolve(type: T.self, name: resolutionName)
                logger.debug(message: "Successfully resolved dependency for type \(T.self) with name: \(resolutionName ?? "nil")")
                return resolved
            } catch {
                logger.error(message: "Failed to resolve dependency for type \(T.self) with name: \(resolutionName ?? "nil"): \(error.localizedDescription)")
                throw error
            }
        }
        
        asyncInitialized = true
    }
    
    /// Asynchronously resolve the dependency
    /// This method allows explicit async access to the dependency
    mutating func resolve() async throws -> T {
        if let value = storage {
            return value
        }
        
        if !asyncInitialized {
            initializeAsync()
        }
        
        guard let task = resolutionTask else {
            throw ContainerError.containerTerminated
        }
        
        let result = try await task.value
        storage = result
        return result
    }
    
    /// Handle resolution errors based on the chosen strategy
    /// - Parameter message: The error message
    /// - Returns: A value of type T (only returned for useDefault strategy)
    private func handleError(_ message: String) -> T {
        let logger = PrimerLogging.shared.logger
        
        switch errorStrategy {
        case .crash:
            logger.error(message: "DI resolution error: \(message)")
            fatalError("DI resolution error: \(message)")
            
        case .returnNil:
            // This only works if T is an optional type
            // Check if T is Optional by using the Mirror API
            let isOptional = Mirror(reflecting: Optional<Any>.none as Any).displayStyle == Mirror(reflecting: Optional<T>.none as Any).displayStyle
            
            if isOptional {
                // If T is Optional<Wrapped>, we can safely return nil as T
                // We need to force-unwrap here because we've verified it's an optional
                logger.warn(message: "Returning nil for failed resolution of type \(T.self)")
                // swiftlint: disable force_cast
                return Optional<Any>.none as! T
                // swiftlint: enable force_cast
            } else {
                logger.error(message: "Cannot use .returnNil strategy with non-optional type \(T.self)")
                fatalError("Cannot use .returnNil strategy with non-optional type \(T.self)")
            }
            
        case .useDefault(let defaultValue):
            logger.warn(message: "Using default value for failed resolution of type \(T.self): \(message)")
            return defaultValue
            
        case .logAndCrash:
            logger.error(message: "DI RESOLUTION ERROR: \(message)")
            logger.error(message: "STACK TRACE:")
            Thread.callStackSymbols.forEach { logger.error($0) }
            fatalError("DI resolution error: \(message)")
        }
    }
}

/// Property wrapper for synchronously injecting dependencies
/// This is less efficient but provides backward compatibility with synchronous code
@propertyWrapper
struct SyncInjected<T> {
    /// Error handling strategy for failed injections
    typealias ErrorStrategy = Injected<T>.ErrorStrategy
    
    /// The underlying async property wrapper
    private var asyncWrapper: Injected<T>
    
    /// Initialize the property wrapper
    /// - Parameters:
    ///   - name: Optional name to distinguish between multiple implementations
    ///   - lazy: Whether to lazily initialize the dependency
    ///   - errorStrategy: Strategy for handling resolution errors
    init(name: String? = nil, lazy: Bool = true, errorStrategy: ErrorStrategy = .crash) {
        self.asyncWrapper = Injected(name: name, lazy: lazy, errorStrategy: errorStrategy)
    }
    
    /// The wrapped value, which resolves the dependency synchronously
    var wrappedValue: T {
        mutating get {
            var wrapper = asyncWrapper
            return wrapper.wrappedValue
        }
    }
    
    /// Provides access to the projectedValue (self)
    var projectedValue: Self {
        return self
    }
}
