#if canImport(UIKit)

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

    var amount: Int {
        guard let amount = state.settings.amount else { fatalError("Apple Pay requires amount value!") }
        return amount

    }
    var applePayConfigId: String? { return state.paymentMethodConfig?.getConfigId(for: .applePay) }
    var currency: Currency {
        guard let currency = state.settings.currency else { fatalError("Apple Pay requires currency value!") }
        return currency
    }
    var merchantIdentifier: String? { return state.settings.merchantIdentifier }
    var countryCode: CountryCode? { return state.settings.countryCode }
    var uxMode: UXMode { return Primer.flow.uxMode }
    var clientToken: DecodedClientToken? { return state.decodedClientToken }

    @Dependency private(set) var tokenizationService: TokenizationServiceProtocol
    @Dependency private(set) var paymentMethodConfigService: PaymentMethodConfigServiceProtocol
    @Dependency private(set) var clientTokenService: ClientTokenServiceProtocol
    @Dependency private(set) var state: AppStateProtocol

    deinit {
        log(logLevel: .debug, message: "🧨 destroyed: \(self.self)")
    }

    func tokenize(instrument: PaymentInstrument, completion: @escaping (Error?) -> Void) {
        let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)
        tokenizationService.tokenize(request: request) { [weak self] result in
            switch result {
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(error)
            case .success(let token):
                switch Primer.flow {
                case .completeDirectCheckout: self?.state.settings.onTokenizeSuccess(token, completion)
                default: completion(nil)
                }
            }
        }
    }
}

#endif
