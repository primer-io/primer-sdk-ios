//
//  Injected.swift
//
//
//  Created by Boris on 7. 5. 2025..
//

import Foundation

// MARK: - Global lock for all Injected instances
/// Global lock for thread safety across all Injected instances
private let injectedLock = NSLock()

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
            _ = wrappedValue
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

            // Thread-safe resolution
            return injectedLock.withLock {
                // Check again after acquiring lock
                if let value = storage {
                    return value
                }

                // Get the container
                guard let container = DIContainer.current else {
                    return handleError("No DI container available")
                }

                do {
                    // Resolve the dependency
                    guard let resolved: T = try container.resolve(name: name) else {
                        return handleError("Resolved nil value for type \(T.self)")
                    }

                    // Cache the resolved value
                    storage = resolved
                    return resolved
                } catch {
                    return handleError(error.localizedDescription)
                }
            }
        }
    }

    /// Provides access to the projectedValue (self)
    var projectedValue: Self {
        return self
    }

    // MARK: - Helper Methods

    /// Handle resolution errors based on the chosen strategy
    /// - Parameter message: The error message
    /// - Returns: A value of type T (only returned for useDefault strategy)
    private func handleError(_ message: String) -> T {
        switch errorStrategy {
        case .crash:
            fatalError("DI resolution error: \(message)")

        case .returnNil:
            // This only works if T is an optional type
            // Check if T is Optional by using the Mirror API
            let isOptional = Mirror(reflecting: Optional<Any>.none as Any).displayStyle == Mirror(reflecting: Optional<T>.none as Any).displayStyle

            if isOptional {
                // If T is Optional<Wrapped>, we can safely return nil as T
                // We need to force-unwrap here because we've verified it's an optional
                // swiftlint: disable force_cast
                return Optional<Any>.none as! T
                // swiftlint: enable force_cast
            } else {
                fatalError("Cannot use .returnNil strategy with non-optional type \(T.self)")
            }

        case .useDefault(let defaultValue):
            return defaultValue

        case .logAndCrash:
            print("DI RESOLUTION ERROR: \(message)")
            print("STACK TRACE:")
            Thread.callStackSymbols.forEach { print($0) }
            fatalError("DI resolution error: \(message)")
        }
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
