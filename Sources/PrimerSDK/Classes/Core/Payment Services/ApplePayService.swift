//
//  ApplePayService.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/4/21.
//

import Foundation


protocol ApplePayServiceProtocol {
    func tokenize(instrument: PaymentInstrument, completion: @escaping (Result<PaymentMethodToken, Error>) -> Void)
    func fetchConfig(_ completion: @escaping (Error?) -> Void)
}

enum ApplePayType {
    case recurring, checkout
}

class ApplePayService: NSObject, ApplePayServiceProtocol {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    func fetchConfig(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.configFetchFailed)
        }
                
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.fetchConfiguration(clientToken: clientToken) { [weak self] (result) in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let config):
                state.paymentMethodConfig = config

                state.viewModels = []

                config.paymentMethods?.forEach({ method in
                    if !method.type.isEnabled { return }
                    state.viewModels.append(PaymentMethodConfigViewModel(config: method))
                })

                // Ensure Apple Pay is always first if present.
                // This is because of Apple's guidelines.
                var viewModels = state.viewModels
                
                for (index, vm) in viewModels.enumerated() {
                    if vm.config.type == .applePay {
                        viewModels.swapAt(0, index)
                    }
                }

                completion(nil)
            }
        }
    }
    
    func tokenize(instrument: PaymentInstrument, completion: @escaping (Result<PaymentMethodToken, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)

        let tokenizationService: TokenizationServiceProtocol = DependencyContainer.resolve()
        tokenizationService.tokenize(request: request) { (result) in
            switch result {
            case .failure(let err):
                completion(.failure(err))
            case .success(let token):
                completion(.success(token))
            }
        }
    }
    
}
