protocol ApplePayViewModelProtocol {
    var amount: Int { get }
    var applePayConfigId: String? { get }
    var currency: Currency { get }
    var merchantIdentifier: String? { get }
    var countryCode: CountryCode? { get }
    func tokenize(
        instrument: PaymentInstrument,
        completion: @escaping (Error?) -> Void
    )
}

class ApplePayViewModel: ApplePayViewModelProtocol {
    
    var amount: Int { return settings.amount }
    var applePayConfigId: String? { return paymentMethodConfigService.getConfigId(for: .APPLE_PAY) }
    var currency: Currency { return settings.currency }
    var merchantIdentifier: String? { return settings.merchantIdentifier }
    var countryCode: CountryCode? { return settings.countryCode }
    var uxMode: UXMode { return settings.uxMode }
    var clientToken: ClientToken? { return clientTokenService.decodedClientToken }
    var onTokenizeSuccess: (_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) -> Void {
        return settings.onTokenizeSuccess
    }
    
    let tokenizationService: TokenizationServiceProtocol
    let paymentMethodConfigService: PaymentMethodConfigServiceProtocol
    let clientTokenService: ClientTokenServiceProtocol
    let settings: PrimerSettings
    
    init(
        with settings: PrimerSettings,
        and clientTokenService: ClientTokenServiceProtocol,
        and tokenizationService: TokenizationServiceProtocol,
        and paymentMethodConfigService: PaymentMethodConfigServiceProtocol
    ) {
        self.settings = settings
        self.clientTokenService = clientTokenService
        self.tokenizationService = tokenizationService
        self.paymentMethodConfigService = paymentMethodConfigService
    }
    
    func tokenize(instrument: PaymentInstrument, completion: @escaping (Error?) -> Void) {
        guard let clientToken = self.clientToken else { return }
        guard let customerId = settings.customerId else { return }
        
        let request = PaymentMethodTokenizationRequest.init(with: uxMode, and: customerId, and: instrument)
        
        tokenizationService.tokenize(with: clientToken, request: request, onTokenizeSuccess: { result in
            switch result {
            case .failure(let error): completion(error)
            case .success(let token):
                switch self.uxMode {
                case .VAULT:
                    completion(nil)
                case .CHECKOUT:
                    self.onTokenizeSuccess(token, completion)
                }
            }
        })
    }
}

class MockApplePayViewModel: ApplePayViewModelProtocol {
    var amount: Int { return 200 }
    
    var applePayConfigId: String? { return "applePayConfigId" }
    
    var currency: Currency { return .EUR }
    
    var merchantIdentifier: String? { "mid" }
    
    var countryCode: CountryCode? { return .FR }
    
    func tokenize(instrument: PaymentInstrument, completion: @escaping (Error?) -> Void) {
        
    }
}
