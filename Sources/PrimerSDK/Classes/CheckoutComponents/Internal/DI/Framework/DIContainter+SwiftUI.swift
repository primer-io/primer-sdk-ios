//
//  DIContainter+SwiftUI.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
extension DIContainer {

    struct DIContainerEnvironmentKey: EnvironmentKey {
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
                logger.debug(message: "Failed to resolve \(String(describing: type)) from DI container")
                instance = fallback()
            }
        } else {
            // Log container unavailability for debugging
            logger.debug(message: "DI Container not available for \(String(describing: type))")
            instance = fallback()
        }

        return StateObject(wrappedValue: instance)
    }

    @MainActor
    static func resolve<T>(_ type: T.Type, from environment: EnvironmentValues, name: String? = nil) throws -> T {
        guard let container = environment.diContainer else {
            throw ContainerError.containerUnavailable
        }
        return try container.resolveSync(type, name: name)
    }

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
                logger.debug(message: "Failed to resolve \(String(describing: type)) from environment DI container")
                return StateObject(wrappedValue: fallback())
            }
        } else {
            // No DI container in environment
            return StateObject(wrappedValue: fallback())
        }
    }
}

@available(iOS 15.0, *)
extension EnvironmentValues {
    var diContainer: (any ContainerProtocol)? {
        get { self[DIContainer.DIContainerEnvironmentKey.self] }
        set { self[DIContainer.DIContainerEnvironmentKey.self] = newValue }
    }
}
