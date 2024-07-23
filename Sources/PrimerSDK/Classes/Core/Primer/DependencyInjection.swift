//
//  DependencyInjection.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 10/02/2021.
//

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

final internal class DependencyContainer {
    
    private static let queue: DispatchQueue = DispatchQueue(label: "primer.dependencycontainer")

    private var dependencies = [String: AnyObject]()

    static var shared: DependencyContainer {
        return _DependencyContainer
    }

    static func register<T>(_ dependency: T) {
        shared.register(dependency)
    }

    static func resolve<T>() -> T {
        shared.resolve()
    }

    private func register<T>(_ dependency: T) {
        let key = String(describing: T.self)
        Self.queue.async(flags: .barrier) { [weak self] in
            self?.dependencies[key] = dependency as AnyObject
        }
    }

    private func resolve<T>() -> T {
        let key = String(describing: T.self)
        
        if let dependency = Self.queue.sync(execute: { dependencies[key] as? T }) {
            return dependency
        }
        
        return Self.queue.sync {
            // Check again in case it was registered while we were waiting
            if let dependency = self.dependencies[key] as? T {
                return dependency
            }
            
            // If still not found, create and register it
            let dependency: T? = self.createDependency(for: key)
            if let dependency = dependency {
                self.dependencies[key] = dependency as AnyObject
            }
            return dependency!
        }
    }
    
    private func createDependency<T>(for key: String) -> T? {
        switch key {
        case String(describing: AppStateProtocol.self):
            return AppState() as? T
        case String(describing: PrimerSettingsProtocol.self):
            return PrimerSettings() as? T
        case String(describing: PrimerThemeProtocol.self):
            return PrimerTheme() as? T
        default:
            return nil
        }
    }
}
