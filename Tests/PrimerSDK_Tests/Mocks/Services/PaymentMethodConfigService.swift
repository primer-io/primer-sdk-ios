//
//  PaymentMethodConfigService.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockPaymentMethodConfigService: PaymentMethodConfigServiceProtocol {

    var viewModels: [PaymentMethodViewModel] = []

    var fetchConfigCalled = false
    
    func fetchConfig(_ completion: @escaping (Error?) -> Void) {
        fetchConfigCalled = true
        completion(nil)
    }
}

#endif
