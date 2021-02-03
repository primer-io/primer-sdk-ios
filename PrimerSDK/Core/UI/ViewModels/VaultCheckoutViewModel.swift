protocol VaultCheckoutViewModelProtocol {
    var paymentMethods: [PaymentMethodToken] { get }
    var mandate: DirectDebitMandate { get }
    var availablePaymentOptions: [PaymentMethodViewModel] { get }
    var selectedPaymentMethodId: String { get }
    var theme: PrimerTheme { get }
    var amountStringed: String { get }
    func loadConfig(_ completion: @escaping (Error?) -> Void)
    func authorizePayment(_ completion: @escaping (Error?) -> Void)
}

class VaultCheckoutViewModel: VaultCheckoutViewModelProtocol {
    var mandate: DirectDebitMandate {
        return state.directDebitMandate
    }
    
    var availablePaymentOptions: [PaymentMethodViewModel] {
        return state.viewModels
    }
    
    var amountStringed: String {
        return state.settings.amount.toCurrencyString(currency: state.settings.currency)
    }
    
    var theme: PrimerTheme { return state.settings.theme }
    
    var paymentMethods: [PaymentMethodToken] {
        if #available(iOS 11.0, *) {
            return state.paymentMethods
        } else {
            return state.paymentMethods.filter {
                switch $0.paymentInstrumentType {
                case .GOCARDLESS_MANDATE: return true
                case .PAYMENT_CARD: return true
                default: return false
                }
            }
        }
    }
    
    var selectedPaymentMethodId: String { return state.selectedPaymentMethod }
    
    var clientTokenService: ClientTokenServiceProtocol
    var vaultService: VaultServiceProtocol
    var paymentMethodConfigService: PaymentMethodConfigServiceProtocol
    var state: AppStateProtocol
    
    init(context: CheckoutContextProtocol) {
        self.clientTokenService = context.serviceLocator.clientTokenService
        self.vaultService = context.serviceLocator.vaultService
        self.paymentMethodConfigService = context.serviceLocator.paymentMethodConfigService
        self.state = context.state
    }
    
    func loadConfig(_ completion: @escaping (Error?) -> Void) {
        if (state.decodedClientToken.exists) {
            paymentMethodConfigService.fetchConfig({ [weak self] error in
                self?.vaultService.loadVaultedPaymentMethods(completion)
            })
        } else {
            clientTokenService.loadCheckoutConfig({ [weak self] error in
                self?.paymentMethodConfigService.fetchConfig({ [weak self] error in
                    self?.vaultService.loadVaultedPaymentMethods(completion)
                })
            })
        }
    }
    
    func authorizePayment(_ completion: @escaping (Error?) -> Void) {
        guard let selectedToken = state.paymentMethods.first(where: { token in
            guard let tokenId = token.token else { return false }
            return tokenId == state.selectedPaymentMethod
        }) else { return }
        self.state.settings.onTokenizeSuccess(selectedToken, completion)
    }
    
}

extension Int {
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
