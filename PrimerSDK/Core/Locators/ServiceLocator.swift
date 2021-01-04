public enum Environment {
    case production, test
}

class ServiceLocator {
    
    let settings: PrimerSettings
    let api = APIClient()
    
    init(settings: PrimerSettings) {
        self.settings = settings
    }
    
    lazy var clientTokenService: ClientTokenServiceProtocol = ClientTokenService(with: settings, and: paymentMethodConfigService)
    lazy var paymentMethodConfigService: PaymentMethodConfigServiceProtocol = PaymentMethodConfigService(
        with: api,
        and: vaultService,
        and: settings
    )
    lazy var paypalService: PayPalService = PayPalService(amount: settings.amount, currency: settings.currency)
    lazy var tokenizationService: TokenizationServiceProtocol = TokenizationService(with: api)
    lazy var vaultService: VaultServiceProtocol = VaultService(customerID: settings.customerId)
    
}
