protocol CardFormViewModelProtocol {
    var flow: PrimerSessionFlow { get }
    func configureView(_ completion: @escaping (Error?) -> Void)
    func tokenize(
        instrument: PaymentInstrument,
        completion: @escaping (Error?) -> Void
    )
}


class CardFormViewModel: CardFormViewModelProtocol {
    var flow: PrimerSessionFlow { return Primer.flow }
    
    //
    @Dependency private(set) var tokenizationService: TokenizationServiceProtocol
    @Dependency private(set) var clientTokenService: ClientTokenServiceProtocol
    @Dependency private(set) var state: AppStateProtocol
    
    deinit {
        log(logLevel: .debug, message: "🧨 destroyed: \(self.self)")
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
            case .failure(let error):
                completion(error)
            case .success(let token):
                Primer.flow.vaulted ? completion(nil) : self?.state.settings.onTokenizeSuccess(token, completion)
            }
        }
    }
}
