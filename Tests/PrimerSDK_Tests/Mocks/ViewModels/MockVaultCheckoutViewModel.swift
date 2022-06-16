//
//  MockVaultCheckoutViewModel.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK
import XCTest

class MockVaultCheckoutViewModel: VaultCheckoutViewModelProtocol {
    var selectedPaymentMethod: PaymentMethodToken?
    
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
        if MockClientTokenService.decodedClientToken.exists {
            let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
            paymentMethodConfigService.fetchConfig({ err in
                if let err = err {
                    completion(err)
                } else {
                    let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
                    vaultService.loadVaultedPaymentMethods(completion)
                }
            })
        } else {
            let clientTokenService: ClientTokenServiceProtocol = DependencyContainer.resolve()
            if clientTokenService is MockClientTokenService {
                (clientTokenService as! MockClientTokenService).fetchClientToken()
            }
        }
    }
    
    func authorizePayment(_ completion: @escaping (Error?) -> Void) {
        
    }
}

#endif
