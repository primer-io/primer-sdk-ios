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

/// Property wrapper for automatically injecting dependencies
@propertyWrapper
public final class Injected<T> {
    /// Error handling strategy for failed injections
    public enum ErrorStrategy {
        /// Throw an error when accessed
        case `throw`
        /// Use a default value if resolution fails
        case useDefault(T)
        /// Log the error and throw
        case logAndThrow
    }

    // MARK: - Properties

    /// Optional name to distinguish between multiple implementations
    private let name: String?

    /// Error handling strategy
    private let errorStrategy: ErrorStrategy

    /// Whether to lazily initialize the dependency
    private let lazyInit: Bool

    /// Storage for the resolved dependency
    private var storage: InjectionResult<T>?

    /// Lock for thread safety
    private let lock = NSLock()

    // MARK: - Initialization

    /// Initialize the property wrapper
    /// - Parameters:
    ///   - name: Optional name to distinguish between multiple implementations
    ///   - lazy: Whether to lazily initialize the dependency
    ///   - errorStrategy: Strategy for handling resolution errors
    public init(name: String? = nil, lazy: Bool = true, errorStrategy: ErrorStrategy = .throw) {
        self.name = name
        self.lazyInit = lazy
        self.errorStrategy = errorStrategy

        if !lazyInit {
            // Eagerly initialize for non-lazy instances
            Task {
                _ = try? await resolveFromContainer()
            }
        }
    }

    // MARK: - Property Wrapper

    /// The wrapped value, which resolves the dependency on first access
    public var wrappedValue: T {
        get {
            do {
                // Return cached value if available
                if let result = lock.withLock({ storage }) {
                    return try handleResult(result)
                }

                // Resolve the dependency
                let result: InjectionResult<T>

                if let container = DIContainer.currentSync {
                    // Fast path: use sync container if available
                    result = resolveFromContainerDirectly(container)
                } else {
                    // Fallback: use semaphore to wait for async resolution
                    result = resolveFromContainerWithSemaphore()
                }

                // Cache the result
                lock.withLock {
                    storage = result
                }

                return try handleResult(result)
            } catch {
                // Convert errors to fatalError for property wrappers that can't throw
                fatalError("Failed to resolve dependency: \(error)")
            }
        }
    }

    /// Provides access to projectedValue for more options
    public var projectedValue: Injected<T> {
        return self
    }

    // MARK: - Resolution Methods

    /// Resolve the dependency asynchronously
    /// - Returns: The resolved dependency
    /// - Throws: ContainerError if resolution fails
    public func resolve() async throws -> T {
        // Return cached value if available
        if let result = lock.withLock({ storage }) {
            return try handleResult(result)
        }

        // Resolve the dependency
        let result = try await resolveFromContainer()

        // Cache the result
        lock.withLock {
            storage = result
        }

        return try handleResult(result)
    }

    /// Reset the cached dependency, forcing re-resolution on next access
    public func reset() {
        lock.withLock {
            storage = nil
        }
    }

    // MARK: - Helper Methods

    /// Resolve the dependency from the container asynchronously
    private func resolveFromContainer() async throws -> InjectionResult<T> {
        guard let container = await DIContainer.current else {
            return .failure(.containerUnavailable)
        }

        do {
            let value = try await container.resolve(T.self, name: name)
            return .success(value)
        } catch let error as ContainerError {
            return .failure(error)
        } catch {
            return .failure(.factoryFailed(TypeKey(T.self, name: name), underlyingError: error))
        }
    }

    /// Resolve the dependency from the container directly (sync access)
    private func resolveFromContainerDirectly(_ container: ContainerProtocol) -> InjectionResult<T> {
        // Start task for async resolution
        let semaphore = DispatchSemaphore(value: 0)
        var result: InjectionResult<T> = .failure(.containerUnavailable)

        Task {
            do {
                let value = try await container.resolve(T.self, name: name)
                result = .success(value)
            } catch let error as ContainerError {
                result = .failure(error)
            } catch {
                result = .failure(.factoryFailed(TypeKey(T.self, name: name), underlyingError: error))
            }
            semaphore.signal()
        }

        // Wait with a timeout
        if semaphore.wait(timeout: .now() + 1.0) == .timedOut {
            return .failure(.containerUnavailable)
        }

        return result
    }

    /// Resolve using a semaphore to wait for async resolution
    private func resolveFromContainerWithSemaphore() -> InjectionResult<T> {
        let semaphore = DispatchSemaphore(value: 0)
        var result: InjectionResult<T> = .failure(.containerUnavailable)

        Task {
            do {
                result = try await resolveFromContainer()
            } catch {
                result = .failure(.containerUnavailable)
            }
            semaphore.signal()
        }

        // Wait with a timeout
        if semaphore.wait(timeout: .now() + 2.0) == .timedOut {
            return .failure(.containerUnavailable)
        }

        return result
    }

    /// Handle the result based on the error strategy
    private func handleResult(_ result: InjectionResult<T>) throws -> T {
        switch result {
        case .success(let value):
            return value

        case .failure(let error):
            switch errorStrategy {
            case .throw:
                throw error

            case .useDefault(let defaultValue):
                return defaultValue

            case .logAndThrow:
                // Log the error
                print("DI RESOLUTION ERROR: \(error)")
                print("STACK TRACE:")
                Thread.callStackSymbols.forEach { print($0) }
                throw error
            }
        }
    }
}

/// Property wrapper specifically for optional dependencies
@propertyWrapper
public final class InjectedOptional<Wrapped> {
    /// Internal storage using the standard Injected wrapper
    private var injected: Injected<Wrapped?>

    /// Initialize the property wrapper
    /// - Parameters:
    ///   - name: Optional name to distinguish between multiple implementations
    ///   - lazy: Whether to lazily initialize the dependency
    public init(name: String? = nil, lazy: Bool = true) {
        self.injected = Injected<Wrapped?>(name: name, lazy: lazy, errorStrategy: .useDefault(nil))
    }

    /// The wrapped value, which resolves the optional dependency
    public var wrappedValue: Wrapped? {
        // Never throws because we use .useDefault(nil)
        return injected.wrappedValue
    }

    /// Provides access to projectedValue for more options
    public var projectedValue: InjectedOptional<Wrapped> {
        return self
    }

    /// Reset the cached dependency, forcing re-resolution on next access
    public func reset() {
        injected.reset()
    }

    /// Resolve the dependency asynchronously
    /// - Returns: The resolved dependency or nil
    public func resolve() async -> Wrapped? {
        try? await injected.resolve()
    }
}

// MARK: - NSLock Extension
extension NSLock {
    /// Execute a closure while the lock is held and return its result
    /// - Parameter closure: The closure to execute
    /// - Returns: The result of the closure
    /// - Throws: Any error thrown by the closure
    @discardableResult
    func withLock<T>(_ closure: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try closure()
    }
}
