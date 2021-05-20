//
//  ApplePayService.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/4/21.
//

import Foundation


protocol ApplePayServiceProtocol {
    func tokenize(instrument: PaymentInstrument, completion: @escaping (Error?) -> Void)
    func fetchConfig(_ completion: @escaping (Error?) -> Void)
}

enum ApplePayType {
    case recurring, checkout
}

class ApplePayService: NSObject, ApplePayServiceProtocol {
    
    deinit {
        print("ApplePayService deinit")
    }
    
    func fetchConfig(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.configFetchFailed)
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.fetchConfiguration(clientToken: clientToken) { [weak self] (result) in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let config):
                state.paymentMethodConfig = config

                state.viewModels = []

                config.paymentMethods?.forEach({ method in
                    guard let type = method.type else { return }
                    if type == .googlePay { return }
                    state.viewModels.append(PaymentMethodViewModel(type: type))
                })

                // ensure Apple Pay is always first if present.
                let viewModels = state.viewModels
                if (viewModels.contains(where: { model in model.type == .applePay})) {
                    var arr = viewModels.filter({ model in model.type != .applePay})

                    if settings.applePayEnabled == true {
                        arr.insert(PaymentMethodViewModel(type: .applePay), at: 0)
                    }

                    state.viewModels = arr
                }

                completion(nil)
            }
        }
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
                DispatchQueue.main.async {
                    Primer.shared.delegate?.checkoutFailed(with: error)
                }
                completion(error)
            case .success(let token):
                DispatchQueue.main.async {
                    if Primer.shared.flow.internalSessionFlow.vaulted {
                        Primer.shared.delegate?.tokenAddedToVault(token)
                    } else {
                        //settings.onTokenizeSuccess(token, completion)
                        Primer.shared.delegate?.authorizePayment(token, completion)
                    }
                }
                completion(nil)
            }
        }
    }
    
}


