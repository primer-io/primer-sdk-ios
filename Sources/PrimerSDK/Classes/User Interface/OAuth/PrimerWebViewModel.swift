//
//  PrimerWebViewModel.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 05/08/2021.
//

#if canImport(UIKit)

import UIKit

internal protocol PrimerWebViewModelProtocol {
    func onRedirect(with url: URL)
    func onError(_ error: Error)
    var onCompletion: ((Result<PaymentMethodToken, Error>) -> Void)! { get set }
}

internal class ApayaWebViewModel: PrimerWebViewModelProtocol {
    
    var onCompletion: ((Result<PaymentMethodToken, Error>) -> Void)!
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func onRedirect(with url: URL) {
        let result = Apaya.WebViewResult.create(from: url)
        
        switch result {
        case .success(let result):
            tokenize(result: result)
        case .failure(let err):
            onCompletion?(.failure(err))
        }
    }

    func onError(_ error: Error) {
        onCompletion?(.failure(error))
    }
    
    func generateWebViewUrl(_ completion: @escaping (Result<String, Error>) -> Void) {
        if configDidLoad() {
            let apayaService: ApayaServiceProtocol = DependencyContainer.resolve()
            apayaService.createPaymentSession(completion)
        } else {
            loadClientToken { [weak self] result in
                switch result {
                case .failure(let error):
                    self?.onCompletion?(.failure(error))
                case .success:
                    guard let self = self, self.configDidLoad() else {
                        self?.onCompletion?(.failure(PrimerError.configFetchFailed))
                        return
                    }

                    self.generateWebViewUrl(completion)
                }
            }
        }
    }

    func tokenize(result: Apaya.WebViewResult) {
        let tokenizationService: TokenizationServiceProtocol = DependencyContainer.resolve()
        
        do {
            let request = try generateTokenizationRequest(with: result)
            tokenizationService.tokenize(request: request) { [weak self] result in
                switch result {
                case .failure(let err):
                    self?.onCompletion?(.failure(err))
                    
                case .success(let paymentMethod):
                    self?.onCompletion?(.success(paymentMethod))
                }
            }
        } catch {
            self.onCompletion?(.failure(error))
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

    private func loadClientToken(_ completion: @escaping (Result<Bool, ApayaException>) -> Void) {
        let clientTokenService: ClientTokenServiceProtocol = DependencyContainer.resolve()
        clientTokenService.loadCheckoutConfig { [weak self] (error) in
            if let error = error {
                self?.onCompletion?(.failure(error))
            } else {
                self?.loadPaymentMethodConfig(completion)
            }
        }
    }

    private func loadPaymentMethodConfig(_ completion: @escaping (Result<Bool, ApayaException>) -> Void) {
        let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
        configService.fetchConfig { [weak self] (error) in
            if let error = error {
                self?.onCompletion?(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }
}

#endif
