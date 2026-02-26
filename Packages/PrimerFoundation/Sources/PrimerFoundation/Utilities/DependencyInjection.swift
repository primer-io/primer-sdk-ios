//
//  DependencyInjection.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@propertyWrapper
struct Dependency<T> {
    var wrappedValue: T

    init() {
        self.wrappedValue = DependencyContainer.resolve()
    }
}

// swiftlint:disable identifier_name
private let _DependencyContainer = DependencyContainer()
// swiftlint:enable identifier_name

public final class DependencyContainer {

    private static let queue: DispatchQueue = DispatchQueue(label: "primer.dependencycontainer")

    private var dependencies = [String: AnyObject]()
    
    public static func resolve<T>() -> T {
        shared.resolve()
    }
    
    public static func register<T>(_ dependency: T) {
        shared.register(dependency)
    }

    static var shared: DependencyContainer {
        _DependencyContainer
    }

    private func register<T>(_ dependency: T) {
        let key = String(describing: T.self)
        Self.queue.async(flags: .barrier) {
            self.dependencies[key] = dependency as AnyObject
        }
    }

    private func resolve<T>() -> T {
        let key = String(describing: T.self)

        return Self.queue.sync(flags: .barrier) {
            guard let dependency = self.dependencies[key] as? T else {
                preconditionFailure("No dependency found for \(key)! must register a dependency before resolve.")
            }
            return dependency
        }
    }
}
