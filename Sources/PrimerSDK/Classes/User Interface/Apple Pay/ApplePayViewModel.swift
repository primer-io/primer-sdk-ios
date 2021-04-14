#if canImport(UIKit)

protocol ApplePayViewModelProtocol {
    var amount: Int? { get }
    var applePayConfigId: String? { get }
    var currency: Currency? { get }
    var merchantIdentifier: String? { get }
    var countryCode: CountryCode? { get }
    func tokenize(
        instrument: PaymentInstrument,
        completion: @escaping (Error?) -> Void
    )
}

class ApplePayViewModel: ApplePayViewModelProtocol {

    var amount: Int? {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings.amount
    }
    
    var applePayConfigId: String? {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.paymentMethodConfig?.getConfigId(for: .applePay)
    }

    var currency: Currency? {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings.currency
    }
    
    var merchantIdentifier: String? {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings.merchantIdentifier
    }
    var countryCode: CountryCode? {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings.countryCode
    }
    var uxMode: UXMode { return Primer.shared.flow.uxMode }
    var clientToken: DecodedClientToken? {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.decodedClientToken
    }

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func tokenize(instrument: PaymentInstrument, completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        let tokenizationService: TokenizationServiceProtocol = DependencyContainer.resolve()
        tokenizationService.tokenize(request: request) { [weak self] result in
            switch result {
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(error)
            case .success(let token):
                switch Primer.shared.flow {
                case .completeDirectCheckout: settings.onTokenizeSuccess(token, completion)
                default: completion(nil)
                }
            }
        }
    }
}

#endif
