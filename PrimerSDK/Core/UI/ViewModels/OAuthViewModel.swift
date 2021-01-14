protocol OAuthViewModelProtocol {
    func generateOAuthURL(with completion: @escaping (Result<String, Error>) -> Void) -> Void
    func tokenize(with completion: @escaping (Error?) -> Void) -> Void
}

class OAuthViewModel: OAuthViewModelProtocol {
    private var clientToken: ClientToken? { return clientTokenService.decodedClientToken }
    private var orderId: String? { return paypalService.orderId }
    private var confirmedBillingAgreement: PayPalConfirmBillingAgreementResponse? { return paypalService.confirmedBillingAgreement }
    private var onTokenizeSuccess: PaymentMethodTokenCallBack { return settings.onTokenizeSuccess }
    
    //
    private let paypalService: PayPalServiceProtocol
    private let tokenizationService: TokenizationServiceProtocol
    private let clientTokenService: ClientTokenServiceProtocol
    private let paymentMethodConfigService: PaymentMethodConfigServiceProtocol
    private let settings: PrimerSettings
    
    init(
        with settings: PrimerSettings,
        and paypalService: PayPalServiceProtocol,
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
    
    private func loadConfig(_ completion: @escaping (Result<String, Error>) -> Void) {
        clientTokenService.loadCheckoutConfig(with: { [weak self] error in
            if (error != nil) {
                completion(.failure(PrimerError.ClientTokenNull))
                return
            }
            self?.generateOAuthURL(with: completion)
        })
    }
    
    func generateOAuthURL(with completion: @escaping (Result<String, Error>) -> Void) {
        guard let clientToken = clientToken else {
            loadConfig(completion)
            return
        }
        
        guard let configId = paymentMethodConfigService.getConfigId(for: .PAYPAL) else { return }
        
        switch Primer.flow.uxMode {
        case .CHECKOUT: paypalService.getAccessToken(with: clientToken, configId: configId, completion: completion)
        case .VAULT: paypalService.getBillingAgreementToken(with: clientToken, configId: configId, completion: completion)
        }
    }
    
    private func generateBillingAgreementConfirmation(with completion: @escaping (Error?) -> Void) {
        guard let clientToken = clientToken else { return }
        print("🎉 generateBillingAgreementConfirmation", clientToken)
        guard let configId = paymentMethodConfigService.getConfigId(for: .PAYPAL) else { return }
        print("🎉 generateBillingAgreementConfirmation", configId)
        paypalService.confirmBillingAgreement(with: clientToken, configId: configId, completion: { [weak self] result in
            switch result {
            case .failure(let error): print("generateBillingAgreementConfirmation", error)
            case .success: self?.tokenize(with: completion)
            }
        })
    }
    
    func tokenize(with completion: @escaping (Error?) -> Void) {
        guard let clientToken = self.clientToken else { return }
        guard let customerId = settings.customerId else { return }
        
        print("🎉 tokenizing")
        
        var instrument: PaymentInstrument
        
        switch Primer.flow.uxMode {
        case .CHECKOUT:
            guard let id = orderId else { return }
            instrument = PaymentInstrument(paypalOrderId: id)
        case .VAULT:
            print("🎉 confirmedBillingAgreement", confirmedBillingAgreement ?? "nil")
            guard let agreement = confirmedBillingAgreement else {
                generateBillingAgreementConfirmation(with: completion)
                return
            }
            print("🎉 agreement", agreement)
            instrument = PaymentInstrument(
                paypalBillingAgreementId: agreement.billingAgreementId,
                shippingAddress: agreement.shippingAddress,
                externalPayerInfo: agreement.externalPayerInfo
            )
        }
        
        let request = PaymentMethodTokenizationRequest.init(with: Primer.flow.uxMode, and: customerId, and: instrument)
        
        tokenizationService.tokenize(with: clientToken, request: request, onTokenizeSuccess: { [weak self] result in
            switch result {
            case .failure(let error): completion(error)
            case .success(let token):
//                guard let uxMode = self?.settings.flow.uxMode else {
//                    self?.generateBillingAgreementConfirmation(with: completion)
//                    return
//                }
                switch Primer.flow.uxMode {
                case .VAULT: completion(nil)
                case .CHECKOUT: self?.onTokenizeSuccess(token, completion)
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
