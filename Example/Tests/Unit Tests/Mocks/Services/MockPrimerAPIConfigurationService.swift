//
//  PaymentMethodConfigService.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockPrimerAPIConfigurationService: PrimerAPIConfigurationServiceProtocol {
    
    var viewModels: [WebRedirectPaymentMethodTokenizationViewModel] = []
    var fetchConfigCalled = false
    let requestDisplayMetadata: Bool?
    
    required init(requestDisplayMetadata: Bool?) {
        self.requestDisplayMetadata = requestDisplayMetadata
    }
    
    func fetchConfiguration() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
    
    func fetchConfigurationIfNeeded() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
    
    func fetchConfigurationAndVaultedPaymentMethods() -> Promise<Void> {
        return Promise()
    }
}

#endif
