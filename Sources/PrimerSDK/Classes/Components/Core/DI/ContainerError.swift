//
//  ContainerError.swift
//
//
//  Created by Boris on 7. 5. 2025..
//

import Foundation

/// Errors that can occur during dependency resolution
enum ContainerError: LocalizedError, Equatable {
    /// The requested dependency was not registered
    case missingFactoryMethod(Any.Type, name: String?)
    
    /// A circular dependency was detected
    case circularDependency(Any.Type, name: String?, resolutionPath: [String])
    
    /// A factory returned an invalid type
    case invalidFactoryReturn(expected: Any.Type, actual: Any.Type)
    
    /// The requested scope does not exist
    case scopeNotFound(String)
    
    /// A scoped dependency is being accessed outside its scope
    case accessingOutOfScope(Any.Type, name: String?, requiredScope: String)
    
    /// The container is being used after it has been terminated
    case containerTerminated
    
    /// An async operation was cancelled
    case operationCancelled
    
    static func == (lhs: ContainerError, rhs: ContainerError) -> Bool {
        switch (lhs, rhs) {
        case (.missingFactoryMethod(let lhsType, let lhsName), .missingFactoryMethod(let rhsType, let rhsName)):
            return String(describing: lhsType) == String(describing: rhsType) && lhsName == rhsName
            
        case (.circularDependency(let lhsType, let lhsName, _), .circularDependency(let rhsType, let rhsName, _)):
            return String(describing: lhsType) == String(describing: rhsType) && lhsName == rhsName
            
        case (.invalidFactoryReturn(let lhsExpected, let lhsActual), .invalidFactoryReturn(let rhsExpected, let rhsActual)):
            return String(describing: lhsExpected) == String(describing: rhsExpected) && 
                   String(describing: lhsActual) == String(describing: rhsActual)
                   
        case (.scopeNotFound(let lhsScope), .scopeNotFound(let rhsScope)):
            return lhsScope == rhsScope
            
        case (.accessingOutOfScope(let lhsType, let lhsName, let lhsScope), 
              .accessingOutOfScope(let rhsType, let rhsName, let rhsScope)):
            return String(describing: lhsType) == String(describing: rhsType) && 
                   lhsName == rhsName && lhsScope == rhsScope
                   
        case (.containerTerminated, .containerTerminated), (.operationCancelled, .operationCancelled):
            return true
            
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case let .missingFactoryMethod(instanceType, name):
            let nameInfo = name != nil ? " (named: \(name!))" : ""
            return "Missing factory method for type: \(instanceType)\(nameInfo)"

        case let .circularDependency(instanceType, name, resolutionPath):
            let nameInfo = name != nil ? " (named: \(name!))" : ""
            let pathInfo = resolutionPath.joined(separator: " → ")
            return "Circular dependency detected while resolving: \(instanceType)\(nameInfo)\nResolution path: \(pathInfo)"

        case let .invalidFactoryReturn(expected, actual):
            return "Factory returned invalid type: expected \(expected), got \(actual)"
            
        case let .scopeNotFound(scopeId):
            return "Scope not found: \(scopeId)"
            
        case let .accessingOutOfScope(instanceType, name, scope):
            let nameInfo = name != nil ? " (named: \(name!))" : ""
            return "Accessing dependency out of scope: \(instanceType)\(nameInfo) requires scope: \(scope)"
            
        case .containerTerminated:
            return "Container has been terminated and cannot be used"
            
        case .operationCancelled:
            return "Dependency resolution operation was cancelled"
        }
    }
    
    var debugDescription: String {
        return errorDescription ?? "Unknown container error"
    }
}
