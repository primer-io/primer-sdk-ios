//
//  ContainerRetainPolicy.swift
//
//
//  Created by Boris on 7. 5. 2025.
//

import Foundation

/// Defines how the container should retain registered dependencies
public enum ContainerRetainPolicy: String, Equatable, Sendable, Codable {
    case transient    // new instance every time
    case singleton    // strong cache
    case weak         // weak cache

    /// Factory method to produce the correct RetentionStrategy
    func makeStrategy() -> RetentionStrategy {
        switch self {
        case .transient:
            return TransientStrategy()
        case .singleton:
            return SingletonStrategy()
        case .weak:
            return WeakStrategy()
        }
    }
}
