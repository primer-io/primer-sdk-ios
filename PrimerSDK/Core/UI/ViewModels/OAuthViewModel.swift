protocol OAuthViewModelProtocol {
    func generateOAuthURL(with completion: @escaping (Result<String, Error>) -> Void) -> Void
    func tokenize(with completion: @escaping (Error?) -> Void) -> Void
}

class OAuthViewModel: OAuthViewModelProtocol {
    private var clientToken: ClientToken? { return clientTokenService.decodedClientToken }
    private var orderId: String? { return paypalService.orderId }
    private var onTokenizeSuccess: (_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) -> Void {
        return settings.onTokenizeSuccess
    }
    
    private let paypalService: PayPalService
    private let tokenizationService: TokenizationServiceProtocol
    private let clientTokenService: ClientTokenServiceProtocol
    private let paymentMethodConfigService: PaymentMethodConfigServiceProtocol
    private let settings: PrimerSettings
    
    init(
        with settings: PrimerSettings,
        and paypalService: PayPalService,
        and tokenizationService: TokenizationServiceProtocol,
        and clientTokenService: ClientTokenServiceProtocol,
        and paymentMethodConfigService: PaymentMethodConfigServiceProtocol
    ) {
        self.settings = settings
        self.paypalService = paypalService
        self.tokenizationService = tokenizationService
        self.clientTokenService = clientTokenService
        self.paymentMethodConfigService = paymentMethodConfigService
    }
    
    func generateOAuthURL(with completion: @escaping (Result<String, Error>) -> Void) {
        guard let clientToken = clientToken else { return }
        guard let configId = paymentMethodConfigService.getConfigId(for: .PAYPAL) else { return }
        
        paypalService.getAccessToken(with: clientToken, and: configId, and: completion)
    }
    
    func tokenize(with completion: @escaping (Error?) -> Void) {
        guard let id = orderId else { return }
        guard let clientToken = self.clientToken else { return }
        guard let customerId = settings.customerId else { return }
        
        let instrument = PaymentInstrument(paypalOrderId: id)
        let request = PaymentMethodTokenizationRequest.init(with: settings.uxMode, and: customerId, and: instrument)
        
        tokenizationService.tokenize(with: clientToken, request: request, onTokenizeSuccess: { result in
            switch result {
            case .failure(let error): completion(error)
            case .success(let token):
                switch self.settings.uxMode {
                case .VAULT:
                    completion(nil)
                case .CHECKOUT:
                    self.onTokenizeSuccess(token, completion)
                }
            }
        })
    }
}

class MockOAuthViewModel: OAuthViewModelProtocol {
    
    var generateOAuthURLCalled = false
    var tokenizeCalled = false
    
    func generateOAuthURL(with completion: @escaping (Result<String, Error>) -> Void) {
        generateOAuthURLCalled = true
    }
    
    func tokenize(with completion: @escaping (Error?) -> Void) {
        tokenizeCalled = true
    }
}
