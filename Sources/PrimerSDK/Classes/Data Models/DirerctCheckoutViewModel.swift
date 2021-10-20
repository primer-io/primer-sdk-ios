//
//  DirerctCheckoutViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 6/8/21.
//

import Foundation

#if canImport(UIKit)

import Foundation

internal protocol DirectCheckoutViewModelProtocol {
    var amountViewModel: AmountViewModel? { get }
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void)
}

internal class DirectCheckoutViewModel: DirectCheckoutViewModelProtocol {
    
    private var amount: Int? {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings.amount
    }
    
    private var currency: Currency? {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings.currency
    }

    var amountViewModel: AmountViewModel? {
        guard let amount = amount, let currency = currency else {
            return nil
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        var model = AmountViewModel(amount: amount, currency: currency)
        
        model.disabled = settings.directDebitHasNoAmount
        
        return model
    }
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) {
        if ClientTokenService.decodedClientToken != nil {
            let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
            paymentMethodConfigService.fetchConfig(completion)
        } else {
            let clientTokenService: ClientTokenServiceProtocol = DependencyContainer.resolve()
            clientTokenService.fetchClientToken { err in
                if let err = err {
                    completion(err)
                } else {
                    let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                    paymentMethodConfigService.fetchConfig(completion)
                }
            }
        }
    }
}

#endif

