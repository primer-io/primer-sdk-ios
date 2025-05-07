//
//  ContainerRetainPolicy.swift
//
//
//  Created by Boris on 7. 5. 2025..
//

import Foundation

/// Defines how the container should retain registered dependencies
enum ContainerRetainPolicy: Equatable {
    /// Create a new instance each time the dependency is resolved
    case `default`

    /// Hold a strong reference to the instance during the container's lifetime (singleton-like)
    case strong

    /// Hold a weak reference to the instance, allowing it to be deallocated when no longer referenced elsewhere
    case weak
}
