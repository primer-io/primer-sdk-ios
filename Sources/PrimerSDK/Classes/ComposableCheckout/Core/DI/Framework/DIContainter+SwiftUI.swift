//
//  DIContainter+SwiftUI.swift
//  
//
//  Created by Boris on 22. 5. 2025..
//

import SwiftUI

/// SwiftUI extensions for the Primer Dependency Injection container
@available(iOS 15.0, *)
extension DIContainer {
    /// Environment key for accessing the DI container in SwiftUI views
    private struct DIContainerEnvironmentKey: EnvironmentKey {
        static let defaultValue: (any ContainerProtocol)? = nil
    }
    
    @MainActor
    static func stateObject<T: ObservableObject>(
        _ type: T.Type = T.self,
        name: String? = nil,
        default fallback: @autoclosure @escaping () -> T
    ) -> StateObject<T> {
        let instance: T

        if let container = currentSync {
            do {
                instance = try container.resolveSync(type, name: name)
            } catch {
                instance = fallback()
            }
        } else {
            instance = fallback()
        }

        return StateObject(wrappedValue: instance)
    }
    
    /// Helper for resolving dependencies in SwiftUI views
    @MainActor
    static func resolve<T>(_ type: T.Type, from environment: EnvironmentValues, name: String? = nil) throws -> T {
        guard let container = environment.diContainer else {
            throw ContainerError.containerUnavailable
        }
        return try container.resolveSync(type, name: name)
    }
    
    /// StateObject creation with DI fallback using environment
    @MainActor
    static func stateObject<T: ObservableObject>(
        _ type: T.Type = T.self,
        name: String? = nil,
        from environment: EnvironmentValues,
        default fallback: @autoclosure @escaping () -> T
    ) -> StateObject<T> {
        if let container = environment.diContainer,
           let resolved = try? container.resolveSync(type, name: name) {
            return StateObject(wrappedValue: resolved)
        } else {
            return StateObject(wrappedValue: fallback())
        }
    }
}

/// Environment values extension for DI container access
@available(iOS 15.0, *)
extension EnvironmentValues {
    var diContainer: (any ContainerProtocol)? {
        get { self[DIContainer.DIContainerEnvironmentKey.self] }
        set { self[DIContainer.DIContainerEnvironmentKey.self] = newValue }
    }
}
