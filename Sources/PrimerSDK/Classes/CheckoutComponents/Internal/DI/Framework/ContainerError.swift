//
//  ContainerError.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

enum ContainerError: Error, Sendable, LocalizedError {
  case dependencyNotRegistered(TypeKey, suggestions: [String] = [])
  case circularDependency(TypeKey, path: [TypeKey])
  case containerUnavailable
  case scopeNotFound(String, availableScopes: [String] = [])
  case typeCastFailed(TypeKey, expected: String, actual: String)
  case factoryFailed(TypeKey, underlyingError: Error)
  case weakUnsupported(TypeKey)

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
      "Register the dependency using container.register(_:) or check the type name and spelling"

    case .circularDependency:
      "Break the circular dependency by using factories, lazy injection, or restructuring your dependencies"

    case .typeCastFailed:
      "Ensure the registered type matches the requested type exactly"

    case .weakUnsupported:
      "Use .singleton or .transient retention policy for value types"

    default:
      nil
    }
  }

  // MARK: - Error Classification

  public var isUserError: Bool {
    switch self {
    case .dependencyNotRegistered, .typeCastFailed, .weakUnsupported:
      true
    default:
      false
    }
  }

  public var isSystemError: Bool {
    switch self {
    case .containerUnavailable:
      true
    default:
      false
    }
  }
}
