protocol OAuthViewModelProtocol {
    var urlSchemeIdentifier: String { get }
    func generateOAuthURL(with completion: @escaping (Result<String, Error>) -> Void) -> Void
    func tokenize(with completion: @escaping (Error?) -> Void) -> Void
}

class OAuthViewModel: OAuthViewModelProtocol {
    
    var urlSchemeIdentifier: String { return state.settings.urlSchemeIdentifier }
    
    private var clientToken: DecodedClientToken? { return state.decodedClientToken }
    private var orderId: String? { return state.orderId }
    private var confirmedBillingAgreement: PayPalConfirmBillingAgreementResponse? { return state.confirmedBillingAgreement }
    private var onTokenizeSuccess: PaymentMethodTokenCallBack { return state.settings.onTokenizeSuccess }
    
    //
    private let paypalService: PayPalServiceProtocol
    private let tokenizationService: TokenizationServiceProtocol
    private let clientTokenService: ClientTokenServiceProtocol
    private let paymentMethodConfigService: PaymentMethodConfigServiceProtocol
    private var state: AppStateProtocol
    
    init(context: CheckoutContextProtocol) {
        self.paypalService = context.serviceLocator.paypalService
        self.tokenizationService = context.serviceLocator.tokenizationService
        self.clientTokenService = context.serviceLocator.clientTokenService
        self.paymentMethodConfigService = context.serviceLocator.paymentMethodConfigService
        self.state = context.state
    }
    
    private func loadConfig(_ completion: @escaping (Result<String, Error>) -> Void) {
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
                self?.generateOAuthURL(with: completion)
            })
        })
    }
    
    func generateOAuthURL(with completion: @escaping (Result<String, Error>) -> Void) {
        if (clientToken != nil && state.paymentMethodConfig != nil) {
            switch Primer.flow.uxMode {
            case .CHECKOUT: paypalService.startOrderSession(completion)
            case .VAULT:
                print("🚀 vault")
                paypalService.startBillingAgreementSession(completion)
            }
        } else {
            loadConfig(completion)
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
