protocol CardFormViewModelProtocol {
    var uxMode: UXMode { get }
    var theme: PrimerTheme { get }
    var cardScannerViewModel: CardScannerViewModelProtocol { get }
    func reload()
    func tokenize(
        instrument: PaymentInstrument,
        completion: @escaping (Error?) -> Void
    )
}


class CardFormViewModel: CardFormViewModelProtocol {
    let cardScannerViewModel: CardScannerViewModelProtocol
    
    var theme: PrimerTheme { return settings.theme }
    
    var uxMode: UXMode { return settings.uxMode }
    
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
    
    func reload() {}
    
    func tokenize(instrument: PaymentInstrument, completion: @escaping (Error?) -> Void) {
        guard let clientToken = clientTokenService.decodedClientToken else { return }
        guard let customerID = settings.customerId else { return }
        
        let request = PaymentMethodTokenizationRequest(
            with: settings.uxMode,
            and: customerID,
            and: instrument
        )
        
        print("🚀 request:", request)
        
        self.tokenizationService.tokenize(with: clientToken, request: request) { [weak self] result in
            switch result {
            case .failure: print("error")
            case .success(let token):
                
                print("🚀 token:", token)
                
                guard let uxMode = self?.settings.uxMode else { return }
                
                switch uxMode {
                case .VAULT: completion(nil)
                default: self?.settings.onTokenizeSuccess(token, completion)
                }
                
            }
        }
    }
}

class MockCardFormViewModel: CardFormViewModelProtocol {
    var cardScannerViewModel: CardScannerViewModelProtocol {
        return MockCardScannerViewModel()
    }
    
    var theme: PrimerTheme {
        return PrimerTheme()
    }
    
    var uxMode: UXMode { return .CHECKOUT }
    
    func reload() {
        
    }
    
    func tokenize(instrument: PaymentInstrument, completion: @escaping (Error?) -> Void) {
        
    }
}
