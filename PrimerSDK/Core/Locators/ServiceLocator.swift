class ServiceLocator: ServiceLocatorProtocol {
    let state: AppStateProtocol
    
    lazy var api: APIClientProtocol = APIClient()
    lazy var clientTokenService: ClientTokenServiceProtocol = ClientTokenService(state: state)
    lazy var paymentMethodConfigService: PaymentMethodConfigServiceProtocol = PaymentMethodConfigService(api: api, state: state)
    lazy var paypalService: PayPalServiceProtocol = PayPalService(api: api, state: state)
    lazy var tokenizationService: TokenizationServiceProtocol = TokenizationService(api: api, state: state)
    lazy var vaultService: VaultServiceProtocol = VaultService(state: state)
    lazy var directDebitService: DirectDebitServiceProtocol = DirectDebitService(api: api, state: state)
    
    init(state: AppStateProtocol) { self.state = state }
}

protocol ServiceLocatorProtocol {
    var clientTokenService: ClientTokenServiceProtocol { get }
    var paymentMethodConfigService: PaymentMethodConfigServiceProtocol { get }
    var paypalService: PayPalServiceProtocol { get }
    var tokenizationService: TokenizationServiceProtocol { get }
    var vaultService: VaultServiceProtocol { get }
    var directDebitService: DirectDebitServiceProtocol { get }
}
