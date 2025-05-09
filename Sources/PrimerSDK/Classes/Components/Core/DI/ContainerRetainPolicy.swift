//
//  ContainerRetainPolicy.swift
//
//
//  Created by Boris on 7. 5. 2025..
//

import Foundation

/// Defines how the container should retain registered dependencies
enum ContainerRetainPolicy: Equatable {
    /// Create a new instance each time the dependency is resolved (transient)
    case `default`

    /// Hold a strong reference to the instance during the container's lifetime (singleton)
    case strong
    
    /// Hold a weak reference to the instance, allowing it to be deallocated when no longer referenced elsewhere
    case weak
    
    /// Hold a strong reference to the instance within a specific scope identified by the scope ID
    case scoped(String)
}

/// A scope represents a lifetime boundary for scoped dependencies
struct DependencyScope: Hashable {
    /// Unique identifier for the scope
    let id: String
    
    /// Optional parent scope for hierarchical scoping
    let parent: DependencyScope?
    
    /// Create a new scope with an optional parent
    /// - Parameters:
    ///   - id: Unique identifier for the scope
    ///   - parent: Optional parent scope
    init(id: String, parent: DependencyScope? = nil) {
        self.id = id
        self.parent = parent
    }
    
    /// Create a child scope from this scope
    /// - Parameter id: Identifier for the child scope
    /// - Returns: A new scope with this scope as its parent
    func childScope(id: String) -> DependencyScope {
        return DependencyScope(id: id, parent: self)
    }
    
    /// Application-wide singleton scope
    static let application = DependencyScope(id: "application")
    
    /// Default request scope (useful for server-side Swift)
    static let request = DependencyScope(id: "request", parent: .application)
    
    /// Session scope (useful for keeping dependencies alive for a user session)
    static let session = DependencyScope(id: "session", parent: .application)
}
