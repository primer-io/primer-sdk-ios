//
//  ContainerRetainPolicy.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Defines how the container should retain registered dependencies
public enum ContainerRetainPolicy: String, Equatable, Sendable, Codable {
    case transient    // new instance every time
    case singleton    // strong cache
    case weak         // weak cache

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
