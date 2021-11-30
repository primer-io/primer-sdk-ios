//
//  PaymentMethodConfigService.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockPaymentMethodConfigService: PaymentMethodConfigServiceProtocol {

    var viewModels: [ExternalPaymentMethodTokenizationViewModel] = []

    var fetchConfigCalled = false
    
    func fetchConfig(_ completion: @escaping (Error?) -> Void) {
        fetchConfigCalled = true
        completion(nil)
    }
    
    func fetchConfig() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
}

#endif
