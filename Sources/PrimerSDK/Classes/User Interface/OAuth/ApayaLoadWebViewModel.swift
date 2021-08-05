//
//  PrimerLoadWebViewModel.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 04/08/2021.
//

#if canImport(UIKit)

internal class PrimerConfigLoader {
    internal func configDidLoad() -> Bool {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.decodedClientToken != nil && state.paymentMethodConfig != nil
    }
    internal func loadConfig(_ completion: @escaping (Result<Bool, ApayaException>) -> Void) {
        let clientTokenService: ClientTokenServiceProtocol = DependencyContainer.resolve()
        clientTokenService.loadCheckoutConfig { [weak self] (error) in
            if let error = error {
                _ = ErrorHandler.shared.handle(error: error)
                completion(.failure(ApayaException.failedApiCall))
            } else {
                self?.loadPaymentMethodConfig(completion)
            }
        }
    }
    internal func loadPaymentMethodConfig(_ completion: @escaping (Result<Bool, ApayaException>) -> Void) {
        let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
        configService.fetchConfig { (error) in
            if let error = error {
                _ = ErrorHandler.shared.handle(error: error)
                completion(.failure(ApayaException.failedApiCall))
            } else {
                completion(.success(true))
            }
        }
    }
}

protocol ApayaLoadWebViewModelProtocol {
    func generateWebViewUrl(_ completion: @escaping (Result<String, Error>) -> Void)
    func tokenize()
}

internal class ApayaLoadWebViewModel: PrimerConfigLoader, ApayaLoadWebViewModelProtocol {
    //
    func generateWebViewUrl(_ completion: @escaping (Result<String, Error>) -> Void) {
        if configDidLoad() {
            let apayaService: ApayaServiceProtocol = DependencyContainer.resolve()
            apayaService.createPaymentSession(completion)
        } else {
            // In case we load this view model right away we will be forced to load the config here.
            // It's probably better if we figure out some middle step so that the payment method view model
            // never needs to worry about the config having loaded.
            // this view should never appear without having loaded the config.
            loadConfig { [weak self] result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success:
                    guard let strongSelf = self, strongSelf.configDidLoad() else {
                        return completion(.failure(PrimerError.configFetchFailed))
                    }
                    // not sure about calling the function from within itself.
                    strongSelf.generateWebViewUrl(completion)
                }
            }
        }
    }
    //
    func tokenize() {
        let state: AppStateProtocol = DependencyContainer.resolve()
        switch state.getApayaResult() {
        case .none:
            navigate(.failure(ApayaException.invalidWebViewResult))
        case .failure(let error):
            switch error {
            case .webViewFlowCancelled:
                navigate(nil)
            default:
                navigate(.failure(error))
            }
        case .success:
            let tokenizationService: TokenizationServiceProtocol = DependencyContainer.resolve()
            let request = generateTokenizationRequest()
            tokenizationService.tokenize(request: request) { [weak self] result in
                switch result {
                case .failure:
                    self?.navigate(.failure(ApayaException.failedApiCall))
                case .success:
                    self?.navigate(.success(true))
                }
            }
        }
    }
    //
    private func navigate(_ result: Result<Bool, Error>?) {
        DispatchQueue.main.async {
            let router: RouterDelegate = DependencyContainer.resolve()
            switch result {
            case .none:
                router.pop()
            case .failure:
                router.show(.error(error: PrimerError.generic))
            case .success:
                router.show(.success(type: .regular))
            }
        }
    }
    //
    private func generateTokenizationRequest() -> PaymentMethodTokenizationRequest {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let instrument = PaymentInstrument(apayaToken: "")
        return PaymentMethodTokenizationRequest(
            paymentInstrument: instrument,
            state: state
        )
    }
}

#endif
