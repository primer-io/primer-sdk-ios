protocol CardFormViewModelProtocol {
    var flow: PrimerSessionFlow { get }
    var theme: PrimerTheme { get }
    var cardScannerViewModel: CardScannerViewModelProtocol { get }
    func configureView(_ completion: @escaping (Error?) -> Void)
    func tokenize(
        instrument: PaymentInstrument,
        completion: @escaping (Error?) -> Void
    )
}


class CardFormViewModel: CardFormViewModelProtocol {
    let cardScannerViewModel: CardScannerViewModelProtocol
    var theme: PrimerTheme { return settings.theme }
    var flow: PrimerSessionFlow { return Primer.flow }
    private var clientToken: ClientToken? { return clientTokenService.decodedClientToken }
    
    //
    let settings: PrimerSettings
    let tokenizationService: TokenizationServiceProtocol
    let clientTokenService: ClientTokenServiceProtocol
    
    init(
        with settings: PrimerSettings,
        and cardScannerViewModel: CardScannerViewModelProtocol,
        and tokenizationService: TokenizationServiceProtocol,
        and clientTokenService: ClientTokenServiceProtocol
    ) {
        self.settings = settings
        self.cardScannerViewModel = cardScannerViewModel
        self.tokenizationService = tokenizationService
        self.clientTokenService = clientTokenService
    }
    
    private func loadConfig(_ completion: @escaping (Error?) -> Void) {
        clientTokenService.loadCheckoutConfig(with: { [weak self] error in
            if (error != nil) {
                completion(PrimerError.ClientTokenNull)
                return
            }
            self?.configureView(completion)
        })
    }
    
    func configureView(_ completion: @escaping (Error?) -> Void) {
        if (clientToken == nil) {
            loadConfig(completion)
            return
        }
        completion(nil)
    }
    
    func tokenize(instrument: PaymentInstrument, completion: @escaping (Error?) -> Void) {
        guard let clientToken = clientTokenService.decodedClientToken else { return }
        guard let customerID = settings.customerId else { return }
        
        let request = PaymentMethodTokenizationRequest(
            with: Primer.flow.uxMode,
            and: customerID,
            and: instrument
        )
        
        self.tokenizationService.tokenize(with: clientToken, request: request) { [weak self] result in
            switch result {
            case .failure(let error): completion(error)
            case .success(let token):
                switch Primer.flow.uxMode {
                case .VAULT: completion(nil)
                default: self?.settings.onTokenizeSuccess(token, completion)
                }
            }
        }
    }
}

class MockCardFormViewModel: CardFormViewModelProtocol {
    var flow: PrimerSessionFlow {
        return .completeDirectCheckout
    }
    
    func configureView(_ completion: @escaping (Error?) -> Void) {
        
    }
    
    var cardScannerViewModel: CardScannerViewModelProtocol {
        return MockCardScannerViewModel()
    }
    var theme: PrimerTheme { return PrimerTheme() }
    
    var tokenizeCalled = false
    
    func tokenize(instrument: PaymentInstrument, completion: @escaping (Error?) -> Void) {
        tokenizeCalled = true
    }
}
