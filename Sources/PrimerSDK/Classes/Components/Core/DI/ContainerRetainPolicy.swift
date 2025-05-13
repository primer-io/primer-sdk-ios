//
//  ContainerRetainPolicy.swift
//
//
//  Created by Boris on 7. 5. 2025.
//

import Foundation

/// Defines how the container should retain registered dependencies
public enum ContainerRetainPolicy: String, Equatable, Sendable, Codable {
    /// Create a new instance each time the dependency is resolved (transient)
    case transient

    /// Hold a strong reference to the instance during the container's lifetime (singleton)
    case singleton

    /// Hold a weak reference to the instance, allowing it to be deallocated when no longer referenced elsewhere
    case weak
}
