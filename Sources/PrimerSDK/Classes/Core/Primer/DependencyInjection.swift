//
//  DependencyInjection.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 10/02/2021.
//

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
        dependencies[key] = dependency as AnyObject
    }

    private func resolve<T>() -> T {
        let key = String(describing: T.self)
        let dependency = dependencies[key] as? T

        if dependency == nil {
            if key == String(describing: AppStateProtocol.self) {
                let appState: AppStateProtocol = AppState()
                DependencyContainer.register(appState)
                return self.resolve()

            } else if key == String(describing: PrimerSettingsProtocol.self) {
                let primerSettings: PrimerSettingsProtocol = PrimerSettings()
                DependencyContainer.register(primerSettings)
                return self.resolve()

            } else if key == String(describing: PrimerThemeProtocol.self) {
                let primerTheme: PrimerThemeProtocol = PrimerTheme()
                DependencyContainer.register(primerTheme)
                return self.resolve()
            }
        }

        precondition(
            dependency != nil,
            "No dependency found for \(key)! must register a dependency before resolve."
        )

        return dependency!
    }
}
