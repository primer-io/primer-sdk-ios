protocol CardFormViewModelProtocol {
    var flow: PrimerSessionFlow { get }
    var theme: PrimerTheme { get }
    func configureView(_ completion: @escaping (Error?) -> Void)
    func tokenize(
        instrument: PaymentInstrument,
        completion: @escaping (Error?) -> Void
    )
}


class CardFormViewModel: CardFormViewModelProtocol {
    var theme: PrimerTheme { return state.settings.theme }
    var flow: PrimerSessionFlow { return Primer.flow }
    
    //
    let tokenizationService: TokenizationServiceProtocol
    let clientTokenService: ClientTokenServiceProtocol
    
    private var state: AppStateProtocol
    
    init(context: CheckoutContextProtocol) {
        self.state = context.state
        self.tokenizationService = context.serviceLocator.tokenizationService
        self.clientTokenService = context.serviceLocator.clientTokenService
    }
    
    func configureView(_ completion: @escaping (Error?) -> Void) {
        if (state.decodedClientToken.exists) {
            completion(nil)
        } else {
            clientTokenService.loadCheckoutConfig({ error in
                if (error.exists) { return completion(PrimerError.ClientTokenNull) }
                completion(nil)
            })
        }
    }
    
    func tokenize(instrument: PaymentInstrument, completion: @escaping (Error?) -> Void) {
        let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)
        self.tokenizationService.tokenize(request: request) { [weak self] result in
            switch result {
            case .failure(let error): completion(error)
            case .success(let token):
                Primer.flow.vaulted ? completion(nil) : self?.state.settings.onTokenizeSuccess(token, completion)
            }
        }
    }
}
