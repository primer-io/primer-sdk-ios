//
//  PrimerLoadWebViewModel.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 04/08/2021.
//

#if canImport(UIKit)

protocol PrimerLoadWebViewModelProtocol: AnyObject {
    func generateWebViewUrl(_ completion: @escaping (Result<String, Error>) -> Void)
    func getWebViewModel() -> PrimerWebViewModelProtocol
    func tokenize()
}

internal class ApayaLoadWebViewModel: PrimerLoadWebViewModelProtocol {
    //
    func generateWebViewUrl(_ completion: @escaping (Result<String, Error>) -> Void) {
        if configDidLoad() {
            let apayaService: ApayaServiceProtocol = DependencyContainer.resolve()
            apayaService.createPaymentSession(completion)
        } else {
            // In case we load this view model right away we will be forced to load the config here.
            // It's probably better if we figure out some middle step so that a payment method view model
            // never needs to worry about the config having loaded.
            // This view should never appear without the config.
            loadConfig { [weak self] result in
                switch result {
                case .failure(let error):
                    _ = ErrorHandler.shared.handle(error: error)
                    self?.navigate(.failure(error))
                case .success:
                    guard let strongSelf = self, strongSelf.configDidLoad() else {
                        self?.navigate(.failure(PrimerError.configFetchFailed))
                        return
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
            navigate(nil)
        case .failure(let error):
            navigate(.failure(error))
        case .success:
            navigate(.success(true)) // this is temporary fix until we're able to tokenize in sandbox. See code below.

//            let tokenizationService: TokenizationServiceProtocol = DependencyContainer.resolve()
//            let request = generateTokenizationRequest()
//            tokenizationService.tokenize(request: request) { [weak self] result in
//                switch result {
//                case .failure:
//                    self?.navigate(.failure(ApayaException.failedApiCall))
//                case .success:
//                    self?.navigate(.success(true))
//                }
//            }
        }
    }
    //
    func navigate(_ result: Result<Bool, Error>?) {
        DispatchQueue.main.async {
            let router: RouterDelegate = DependencyContainer.resolve()
            switch result {
            case .none:
                // The merchant should detect that this cancels here, however we may need to align on
                // what to do in the case of cancelled flows - what is the ideal experience and what
                // is the current expectation of integrating developers?
                Primer.shared.delegate?.checkoutFailed?(with: PrimerError.userCancelled)
                router.pop()
            case .failure(let error):
                Primer.shared.delegate?.checkoutFailed?(with: error)
                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                let router: RouterDelegate = DependencyContainer.resolve()
                if settings.hasDisabledSuccessScreen {
                    router.root?.onDisabledSuccessScreenDismiss()
                } else {
                    router.show(.error(error: PrimerError.generic))
                }
            case .success:
                router.show(.success(type: .regular))
            }
        }
    }

    private func generateTokenizationRequest(with result: Apaya.WebViewResult) -> PaymentMethodTokenizationRequest {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let instrument = PaymentInstrument(mx: result.mxNumber, mnc: result.mnc, mcc: result.mcc)
        return PaymentMethodTokenizationRequest(
            paymentInstrument: instrument,
            state: state
        )
    }

    func getWebViewModel() -> PrimerWebViewModelProtocol {
        let apayaWebViewModel: ApayaWebViewModel = DependencyContainer.resolve()
        return apayaWebViewModel
    }

    private func configDidLoad() -> Bool {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.decodedClientToken != nil && state.paymentMethodConfig != nil
    }

    private func loadConfig(_ completion: @escaping (Result<Bool, ApayaException>) -> Void) {
        let clientTokenService: ClientTokenServiceProtocol = DependencyContainer.resolve()
        clientTokenService.loadCheckoutConfig { [weak self] (error) in
            if let error = error {
                _ = ErrorHandler.shared.handle(error: error)
                self?.navigate(.failure(error))
            } else {
                self?.loadPaymentMethodConfig(completion)
            }
        }
    }

    private func loadPaymentMethodConfig(_ completion: @escaping (Result<Bool, ApayaException>) -> Void) {
        let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
        configService.fetchConfig { [weak self] (error) in
            if let error = error {
                _ = ErrorHandler.shared.handle(error: error)
                self?.navigate(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }
}

#endif
