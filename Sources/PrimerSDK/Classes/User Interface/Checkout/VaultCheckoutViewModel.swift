#if canImport(UIKit)

internal protocol VaultCheckoutViewModelProtocol {
    var paymentMethods: [PaymentMethodToken] { get }
    var mandate: DirectDebitMandate { get }
    var availablePaymentOptions: [PaymentMethodViewModel] { get }
    var selectedPaymentMethodId: String { get }
    var amountStringed: String? { get }
    func loadConfig(_ completion: @escaping (Error?) -> Void)
    func authorizePayment(_ completion: @escaping (Error?) -> Void)
}

internal class VaultCheckoutViewModel: VaultCheckoutViewModelProtocol {
    var mandate: DirectDebitMandate {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.directDebitMandate
    }

    var availablePaymentOptions: [PaymentMethodViewModel] {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.viewModels
    }

    var amountStringed: String? {
        if Primer.shared.flow.internalSessionFlow.vaulted { return nil }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        guard let amount = settings.amount else { return "" }
        guard let currency = settings.currency else { return "" }
        return amount.toCurrencyString(currency: currency)
    }

    var paymentMethods: [PaymentMethodToken] {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        if #available(iOS 11.0, *) {
            return state.paymentMethods
        } else {
            return state.paymentMethods.filter {
                switch $0.paymentInstrumentType {
                case .goCardless: return true
                case .card: return true
                default: return false
                }
            }
        }
    }

    var selectedPaymentMethodId: String {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.selectedPaymentMethod
    }

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func loadConfig(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        if state.decodedClientToken.exists {
            let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
            paymentMethodConfigService.fetchConfig({ err in
                if let err = err {
                    completion(err)
                } else {
                    let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
                    vaultService.loadVaultedPaymentMethods(completion)
                }
            })
        } else {
            let clientTokenService: ClientTokenServiceProtocol = DependencyContainer.resolve()
            clientTokenService.loadCheckoutConfig({ err in
                if let err = err {
                    completion(err)
                } else {
                    let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                    paymentMethodConfigService.fetchConfig({ err in
                        if let err = err {
                            completion(err)
                        } else {
                            let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
                            vaultService.loadVaultedPaymentMethods(completion)
                        }
                    })
                }
            })
        }
    }

    func authorizePayment(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        guard let selectedToken = state.paymentMethods.first(where: { token in
            guard let tokenId = token.token else { return false }
            return tokenId == state.selectedPaymentMethod
        }) else { return }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        settings.authorizePayment(selectedToken, completion)
        settings.onTokenizeSuccess(selectedToken, completion)
    }

}

internal extension Int {
    func toCurrencyString(currency: Currency) -> String {
        switch currency {
        case .USD: return String(format: "$%.2f", Float(self) / 100)
        case .EUR: return String(format: "€%.2f", Float(self) / 100)
        case .GBP: return String(format: "£%.2f", Float(self) / 100)
        default:
            return "\(self) \(currency.rawValue)"
        }
    }
}

#endif
