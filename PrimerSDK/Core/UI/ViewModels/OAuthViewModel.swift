protocol OAuthViewModelProtocol {
    var urlSchemeIdentifier: String { get }
    func generateOAuthURL(_ host: OAuthHost, with completion: @escaping (Result<String, Error>) -> Void) -> Void
    func tokenize(with completion: @escaping (Error?) -> Void) -> Void
}

class OAuthViewModel: OAuthViewModelProtocol {
    
    var urlSchemeIdentifier: String {
        guard let identifier = state.settings.urlSchemeIdentifier else {
            fatalError("OAuth requires URL scheme identifier!")
        }
        
        return identifier
    }
    
    private var clientToken: DecodedClientToken? { return state.decodedClientToken }
    private var orderId: String? { return state.orderId }
    private var confirmedBillingAgreement: PayPalConfirmBillingAgreementResponse? { return state.confirmedBillingAgreement }
    private var onTokenizeSuccess: PaymentMethodTokenCallBack { return state.settings.onTokenizeSuccess }
    
    @Dependency private(set) var paypalService: PayPalServiceProtocol
    @Dependency private(set) var tokenizationService: TokenizationServiceProtocol
    @Dependency private(set) var clientTokenService: ClientTokenServiceProtocol
    @Dependency private(set) var paymentMethodConfigService: PaymentMethodConfigServiceProtocol
    @Dependency private(set) var klarnaService: KlarnaServiceProtocol
    @Dependency private(set) var state: AppStateProtocol
    
    deinit {
        log(logLevel: .debug, message: "🧨 destroyed: \(self.self)")
    }
    
    private func loadConfig(_ host: OAuthHost, _ completion: @escaping (Result<String, Error>) -> Void) {
        clientTokenService.loadCheckoutConfig({ [weak self] error in
            if (error != nil) {
                completion(.failure(PrimerError.PayPalSessionFailed))
                return
            }
            self?.paymentMethodConfigService.fetchConfig({ [weak self] error in
                if (error != nil) {
                    completion(.failure(PrimerError.PayPalSessionFailed))
                    return
                }
                self?.generateOAuthURL(host, with: completion)
            })
        })
    }
    
    func generateOAuthURL(_ host: OAuthHost, with completion: @escaping (Result<String, Error>) -> Void) {
        if (clientToken != nil && state.paymentMethodConfig != nil) {
            
            if (host == .klarna) {
                return klarnaService.createPaymentSession(completion)
//                return completion(.success("https://pay.playground.klarna.com/eu/9IUNvHa"))
            }
            
            switch Primer.flow.uxMode {
            case .CHECKOUT: paypalService.startOrderSession(completion)
            case .VAULT: paypalService.startBillingAgreementSession(completion)
            }
        } else {
            loadConfig(host, completion)
            return
        }
    }
    
    private func generateBillingAgreementConfirmation(with completion: @escaping (Error?) -> Void) {
        paypalService.confirmBillingAgreement({ [weak self] result in
            switch result {
            case .failure(let error): print("generateBillingAgreementConfirmation", error)
            case .success: self?.tokenize(with: completion)
            }
        })
    }
    
    func tokenize(with completion: @escaping (Error?) -> Void) {
        
        var instrument: PaymentInstrument
        
        switch Primer.flow.uxMode {
        case .CHECKOUT:
            guard let id = orderId else { return }
            instrument = PaymentInstrument(paypalOrderId: id)
        case .VAULT:
            guard let agreement = confirmedBillingAgreement else {
                generateBillingAgreementConfirmation(with: completion)
                return
            }
            instrument = PaymentInstrument(
                paypalBillingAgreementId: agreement.billingAgreementId,
                shippingAddress: agreement.shippingAddress,
                externalPayerInfo: agreement.externalPayerInfo
            )
        }
        
        let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)
        
        tokenizationService.tokenize(request: request) { [weak self] result in
            switch result {
            case .failure(let error): completion(error)
            case .success(let token):
                switch Primer.flow.uxMode {
                case .VAULT: completion(nil)
                case .CHECKOUT: self?.onTokenizeSuccess(token, completion)
                }
            }
        }
    }
}
