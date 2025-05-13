//
//  ContainerError.swift
//
//
//  Created by Boris on 7. 5. 2025.
//

import Foundation

/// Errors that can occur during dependency resolution
public enum ContainerError: Error, Sendable {
    /// The requested dependency was not registered
    case dependencyNotRegistered(TypeKey)

    /// A circular dependency was detected
    case circularDependency(TypeKey, path: [TypeKey])

    /// A factory returned an invalid type
    case invalidTypeReturned(expected: TypeKey, actual: Any.Type)

    /// The container has been terminated and is no longer available
    case containerUnavailable

    /// The requested scope was not found
    case scopeNotFound(String)

    /// The dependency could not be cast to the requested type
    case typeCastFailed(TypeKey, Any.Type)

    /// Factory failed with an error
    case factoryFailed(TypeKey, underlyingError: Error)
}

// MARK: - LocalizedError Implementation
extension ContainerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .dependencyNotRegistered(key):
            return "Dependency not registered: \(key)"

        case let .circularDependency(key, path):
            let pathString = path.map { "\($0)" }.joined(separator: " → ")
            return "Circular dependency detected while resolving \(key). Resolution path: \(pathString)"

        case let .invalidTypeReturned(expected, actual):
            return "Factory returned invalid type: expected \(expected), got \(actual)"

        case .containerUnavailable:
            return "The container has been terminated and is no longer available"

        case let .scopeNotFound(scopeId):
            return "Scope not found: \(scopeId)"

        case let .typeCastFailed(key, type):
            return "Could not cast resolved dependency \(key) to type \(type)"

        case let .factoryFailed(key, error):
            return "Factory for \(key) failed with error: \(error.localizedDescription)"
        }
    }
}
