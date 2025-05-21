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
    @MainActor
    static func stateObject<T: ObservableObject>(
        _ type: T.Type = T.self,
        name: String? = nil,
        default fallback: @autoclosure @escaping () -> T
    ) -> StateObject<T> {
        let instance: T

        if let container = currentSync {
            do {
                instance = try container.resolve(type, name: name)
            } catch {
                instance = fallback()
            }
        } else {
            instance = fallback()
        }

        return StateObject(wrappedValue: instance)
    }
}
