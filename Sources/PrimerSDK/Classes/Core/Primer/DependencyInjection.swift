//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

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
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
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
            if key == String(describing: ClientSessionServiceProtocol.self) {
                let clientSessionService: ClientSessionServiceProtocol = ClientSessionService()
                DependencyContainer.register(clientSessionService)
                return self.resolve()
                
            } else if key == String(describing: ClientTokenServiceProtocol.self) {
                let clientTokenService: ClientTokenServiceProtocol = ClientTokenService()
                DependencyContainer.register(clientTokenService)
                return self.resolve()
                
            } else if key == String(describing: CreateResumePaymentServiceProtocol.self) {
                let createResumePaymentService: CreateResumePaymentServiceProtocol = CreateResumePaymentService()
                DependencyContainer.register(createResumePaymentService)
                return self.resolve()
                
            } else if key == String(describing: AppStateProtocol.self) {
                let appState: AppStateProtocol = AppState()
                DependencyContainer.register(appState)
                return self.resolve()
                
            } else if key == String(describing: PrimerSettingsProtocol.self) {
                let primerSettings: PrimerSettingsProtocol = PrimerSettings()
                DependencyContainer.register(primerSettings)
                return self.resolve()
                
            } else if key == String(describing: PaymentMethodConfigServiceProtocol.self) {
                let apiConfiguration: PaymentMethodConfigServiceProtocol = PaymentMethodConfigService()
                DependencyContainer.register(apiConfiguration)
                return self.resolve()
                
            } else if key == String(describing: PrimerAPIClientProtocol.self) {
                let primerAPIClient: PrimerAPIClientProtocol = PrimerAPIClient()
                DependencyContainer.register(primerAPIClient)
                return self.resolve()
                
            } else if key == String(describing: VaultCheckoutViewModelProtocol.self) {
                let vaultCheckoutViewModel: VaultCheckoutViewModelProtocol = VaultCheckoutViewModel()
                DependencyContainer.register(vaultCheckoutViewModel)
                return self.resolve()
                
            } else if key == String(describing: VaultServiceProtocol.self) {
                let vaultService: VaultServiceProtocol = VaultService()
                DependencyContainer.register(vaultService)
                return self.resolve()
                
            } else if key == String(describing: PayPalServiceProtocol.self) {
                let payPalService: PayPalServiceProtocol = PayPalService()
                DependencyContainer.register(payPalService)
                return self.resolve()
                
            } else if key == String(describing: TokenizationServiceProtocol.self) {
                let tokenizationService: TokenizationServiceProtocol = TokenizationService()
                DependencyContainer.register(tokenizationService)
                return self.resolve()
                
            } else if key == String(describing: VaultPaymentMethodViewModelProtocol.self) {
                let vaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol = VaultPaymentMethodViewModel()
                DependencyContainer.register(vaultPaymentMethodViewModel)
                return self.resolve()
                
            } else if key == String(describing: ExternalViewModelProtocol.self) {
                let externalViewModel: ExternalViewModelProtocol = ExternalViewModel()
                DependencyContainer.register(externalViewModel)
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

#endif
