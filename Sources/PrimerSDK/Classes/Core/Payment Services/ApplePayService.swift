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
