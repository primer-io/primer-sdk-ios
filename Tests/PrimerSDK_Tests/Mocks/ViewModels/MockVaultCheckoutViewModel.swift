//
//  MockVaultCheckoutViewModel.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockVaultCheckoutViewModel: VaultCheckoutViewModelProtocol {
    var selectedPaymentMethod: PaymentMethodToken?
    
    var mandate: DirectDebitMandate {
        return DirectDebitMandate()
    }
    
    var availablePaymentOptions: [PaymentMethodTokenizationViewModelProtocol] {
        return []
    }
    
    var amountStringed: String? {
        return nil
    }
    
    var paymentMethods: [PaymentMethodToken] {
        return []
    }
    
    var selectedPaymentMethodToken: String? = "id"
    
    func loadConfig(_ completion: @escaping (Error?) -> Void) {
        let clientTokenService: ClientTokenServiceProtocol = DependencyContainer.resolve()
        clientTokenService.fetchClientToken({ err in
            if let err = err {
                completion(err)
            } else {
                let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                paymentMethodConfigService.fetchConfig({ err in
                    if let err = err {
                        completion(err)
                    } else {
                        let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
                        vaultService.loadVaultedPaymentMethods(completion)
                    }
                })
            }
        })
    }
    
    func authorizePayment(_ completion: @escaping (Error?) -> Void) {
        
    }
}

#endif
