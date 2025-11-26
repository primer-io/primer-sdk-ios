//
//  SwiftUI+DI.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
extension View {

    func injectDependencies() -> some View {
        modifier(DependencyInjectionModifier())
    }

    func withResolvedDependency<T>(
        _ type: T.Type,
        name: String? = nil,
        perform action: @escaping (T) -> Void
    ) -> some View {
        modifier(DependencyResolutionModifier(type: type, name: name, action: action))
    }
}

@available(iOS 15.0, *)
struct DependencyInjectionModifier: ViewModifier {
    @Environment(\.diContainer) private var container

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard container != nil else {
                    // DIContainer not available in environment
                    return
                }
            }
    }
}

@available(iOS 15.0, *)
struct DependencyResolutionModifier<T>: ViewModifier {
    let type: T.Type
    let name: String?
    let action: (T) -> Void

    @Environment(\.diContainer) private var container

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard let container else {
                    return
                }

                do {
                    let resolved = try container.resolveSync(type, name: name)
                    action(resolved)
                } catch {
                    // Failed to resolve dependency
                }
            }
    }
}

/// Property wrapper for injecting dependencies into SwiftUI views
@available(iOS 15.0, *)
@propertyWrapper
public struct Injected<T>: DynamicProperty {
    @Environment(\.diContainer) private var container

    private let type: T.Type
    private let name: String?
    @State private var resolvedValue: T?

    public init(_ type: T.Type, name: String? = nil) {
        self.type = type
        self.name = name
    }

    public var wrappedValue: T? {
        get {
            if resolvedValue == nil, let container = container {
                resolvedValue = try? container.resolveSync(type, name: name)
            }
            return resolvedValue
        }
        mutating set {
            resolvedValue = newValue
        }
    }

    public var projectedValue: Binding<T?> {
        Binding(
            get: { wrappedValue },
            set: { resolvedValue = $0 }
        )
    }
}

/// Property wrapper for required dependencies (non-optional)
@available(iOS 15.0, *)
@propertyWrapper
public struct RequiredInjected<T>: DynamicProperty {
    @Environment(\.diContainer) private var container

    private let type: T.Type
    private let name: String?
    private let fallback: () -> T
    @State private var resolvedValue: T?

    public init(_ type: T.Type, name: String? = nil, fallback: @escaping @autoclosure () -> T) {
        self.type = type
        self.name = name
        self.fallback = fallback
    }

    public var wrappedValue: T {
        get {
            if let resolved = resolvedValue {
                return resolved
            }

            if let container,
               let resolved = try? container.resolveSync(type, name: name)
            {
                resolvedValue = resolved
                return resolved
            }

            let fallbackValue = fallback()
            resolvedValue = fallbackValue
            return fallbackValue
        }
        mutating set {
            resolvedValue = newValue
        }
    }
}
