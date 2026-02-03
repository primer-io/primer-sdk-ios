//
//  ContainerError.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Enhanced errors with more context and recovery suggestions
public enum ContainerError: Error, Sendable, LocalizedError {
  /// The requested dependency was not registered
  case dependencyNotRegistered(TypeKey, suggestions: [String] = [])

  /// A circular dependency was detected
  case circularDependency(TypeKey, path: [TypeKey])

  /// The container has been terminated and is no longer available
  case containerUnavailable

  /// The requested scope was not found
  case scopeNotFound(String, availableScopes: [String] = [])

  /// The dependency could not be cast to the requested type
  case typeCastFailed(TypeKey, expected: Any.Type, actual: Any.Type)

  /// Factory failed with an error
  case factoryFailed(TypeKey, underlyingError: Error)

  /// Tried to register or resolve a `.weak` dependency for a non‐class type
  case weakUnsupported(TypeKey)

  // MARK: - Error with Context

  public var errorDescription: String? {
    switch self {
    case let .dependencyNotRegistered(key, suggestions):
      var message = "Dependency not registered: \(key)"
      if !suggestions.isEmpty {
        message += "\nSuggestions: \(suggestions.joined(separator: ", "))"
      }
      return message

    case let .circularDependency(key, path):
      let pathString = path.map { "\($0)" }.joined(separator: " → ")
      return "Circular dependency detected while resolving \(key).\nResolution path: \(pathString)"

    case .containerUnavailable:
      return "The container has been terminated and is no longer available"

    case let .scopeNotFound(scopeId, available):
      var message = "Scope not found: \(scopeId)"
      if !available.isEmpty {
        message += "\nAvailable scopes: \(available.joined(separator: ", "))"
      }
      return message

    case let .typeCastFailed(key, expected, actual):
      return "Type cast failed for \(key).\nExpected: \(expected)\nActual: \(actual)"

    case let .factoryFailed(key, error):
      return "Factory for \(key) failed with error: \(error.localizedDescription)"

    case let .weakUnsupported(key):
      return "Cannot weakly cache dependency \(key) because it is not a class type"
    }
  }

  // MARK: - Recovery Suggestions

  public var recoverySuggestion: String? {
    switch self {
    case .dependencyNotRegistered:
      return
        "Register the dependency using container.register(_:) or check the type name and spelling"

    case .circularDependency:
      return
        "Break the circular dependency by using factories, lazy injection, or restructuring your dependencies"

    case .typeCastFailed:
      return "Ensure the registered type matches the requested type exactly"

    case .weakUnsupported:
      return "Use .singleton or .transient retention policy for value types"

    default:
      return nil
    }
  }

  // MARK: - Error Classification

  public var isUserError: Bool {
    switch self {
    case .dependencyNotRegistered, .typeCastFailed, .weakUnsupported:
      return true
    default:
      return false
    }
  }

  public var isSystemError: Bool {
    switch self {
    case .containerUnavailable:
      return true
    default:
      return false
    }
  }
}
