//
//  ContainerError.swift
//
//
//  Created by Boris on 7. 5. 2025..
//

import Foundation

/// Errors that can occur during dependency resolution
enum ContainerError: LocalizedError {
    /// The requested dependency was not registered
    case missingFactoryMethod(Any, name: String?)
    /// A circular dependency was detected
    case circularDependency(Any, name: String?)
    /// A factory returned an invalid type
    case invalidFactoryReturn(expected: Any, actual: Any)

    var errorDescription: String? {
        switch self {
        case let .missingFactoryMethod(instanceType, name):
            let nameInfo = name != nil ? " (named: \(name!))" : ""
            return "Missing factory method for type: \(instanceType)\(nameInfo)"

        case let .circularDependency(instanceType, name):
            let nameInfo = name != nil ? " (named: \(name!))" : ""
            return "Circular dependency detected while resolving: \(instanceType)\(nameInfo)"

        case let .invalidFactoryReturn(expected, actual):
            return "Factory returned invalid type: expected \(expected), got \(actual)"
        }
    }
}
