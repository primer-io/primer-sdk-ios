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
    func loadConfig() -> Promise<Void> {
        return Promise()
    }
    
    var selectedPaymentMethod: PrimerPaymentMethodTokenData?
    
    var availablePaymentOptions: [PaymentMethodTokenizationViewModelProtocol] {
        return []
    }
    
    var amountStringed: String? {
        return nil
    }
    
    var paymentMethods: [PrimerPaymentMethodTokenData] {
        return []
    }
    
    var selectedPaymentMethodToken: String? = "id"
    
    func loadConfig(_ completion: @escaping (Error?) -> Void) {
        if MockClientTokenService.decodedClientToken.exists {
            let configurationService: PrimerAPIConfigurationServiceProtocol = DependencyContainer.resolve()
            firstly {
                configurationService.fetchConfiguration()
            }
            .done {
                let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
                vaultService.loadVaultedPaymentMethods(completion)
            }
            .catch { err in
                completion(err)
            }
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
