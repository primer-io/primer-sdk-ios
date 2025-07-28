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
    internal struct DIContainerEnvironmentKey: EnvironmentKey {
        static let defaultValue: (any ContainerProtocol)? = nil
    }

    @MainActor
    static func stateObject<T: ObservableObject>(
        _ type: T.Type = T.self,
        name: String? = nil,
        default fallback: @autoclosure @escaping () -> T
    ) -> StateObject<T> {
        let instance: T

        // Access currentSync is now properly MainActor-isolated
        if let container = currentSync {
            do {
                instance = try container.resolveSync(type, name: name)
            } catch {
                // Log resolution failure for debugging
                logger.warn(message: "Failed to resolve \(String(describing: type)) from DI container: \(error), using fallback")
                instance = fallback()
            }
        } else {
            // Log container unavailability for debugging
            logger.warn(message: "DI Container not available for \(String(describing: type)), using fallback")
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
        if let container = environment.diContainer {
            do {
                let resolved = try container.resolveSync(type, name: name)
                return StateObject(wrappedValue: resolved)
            } catch {
                logger.warn(message: "Failed to resolve \(String(describing: type)) from environment DI container: \(error), using fallback")
                return StateObject(wrappedValue: fallback())
            }
        } else {
            logger.debug(message: "No DI container in environment for \(String(describing: type)), using fallback")
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
