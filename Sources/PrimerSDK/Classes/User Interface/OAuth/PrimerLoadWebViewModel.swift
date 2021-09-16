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
    func navigate(_ result: Result<Bool, Error>?)
    func tokenize()
}

internal class ApayaLoadWebViewModel: PrimerLoadWebViewModelProtocol {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

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

    func tokenize() {
        let state: AppStateProtocol = DependencyContainer.resolve()
        switch state.getApayaResult() {
        case .none:
            navigate(nil)
        case .failure(let error):
            navigate(.failure(error))
        case .success(let result):
            let tokenizationService: TokenizationServiceProtocol = DependencyContainer.resolve()
            
            do {
                let request = try generateTokenizationRequest(with: result)
                tokenizationService.tokenize(request: request) { [weak self] result in
                    switch result {
                    case .failure(let err):
                        DispatchQueue.main.async {
                            self?.navigate(.failure(PrimerError.tokenizationRequestFailed))
                            Primer.shared.delegate?.checkoutFailed?(with: err)
                        }
                        
                    case .success(let paymentMethodToken):
                        DispatchQueue.main.async {
                            if Primer.shared.flow.internalSessionFlow.vaulted {
                                self?.navigate(.success(true))
                                Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, { (err) in
                                    
                                })
                            } else {
                                Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, { (err) in
                                    if let err = err {
                                        self?.navigate(.failure(err))
                                    } else {
                                        self?.navigate(.success(true))
                                    }
                                })
                            }
                            
                            
                        }
                    }
                }
            } catch {
                self.navigate(.failure(PrimerError.tokenizationRequestFailed))
            }
        }
    }

    func navigate(_ result: Result<Bool, Error>?) {
        DispatchQueue.main.async {
            switch result {
            case .none:
                // The merchant should detect that this cancels here, however we may need to align on
                // what to do in the case of cancelled flows - what is the ideal experience and what
                // is the current expectation of integrating developers?
                let err = PrimerError.userCancelled
                Primer.shared.delegate?.checkoutFailed?(with: err)
                
                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

                if settings.hasDisabledSuccessScreen {
                    Primer.shared.dismiss()
                } else {
                    let evc = ErrorViewController(message: err.localizedDescription)
                    evc.view.translatesAutoresizingMaskIntoConstraints = false
                    evc.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true
                    Primer.shared.primerRootVC?.show(viewController: evc)
                }
                
            case .failure(let error):
                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

                if settings.hasDisabledSuccessScreen {
                    Primer.shared.dismiss()
                } else {
                    let evc = ErrorViewController(message: error.localizedDescription)
                    evc.view.translatesAutoresizingMaskIntoConstraints = false
                    evc.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true
                    Primer.shared.primerRootVC?.show(viewController: evc)
                }
                
            case .success:
                let svc = SuccessViewController()
                svc.view.translatesAutoresizingMaskIntoConstraints = false
                svc.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true
                Primer.shared.primerRootVC?.show(viewController: svc)
            }
        }
    }

    private func generateTokenizationRequest(with result: Apaya.WebViewResult) throws -> PaymentMethodTokenizationRequest {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let currencyStr = settings.currency?.rawValue else {
            throw PaymentException.missingCurrency
        }

        let instrument = PaymentInstrument(mx: result.mxNumber,
                                           mnc: result.mnc,
                                           mcc: result.mcc,
                                           hashedIdentifier: result.hashedIdentifier,
                                           productId: result.productId,
                                           currencyCode: currencyStr)
        
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
                self?.navigate(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }
}

#endif
