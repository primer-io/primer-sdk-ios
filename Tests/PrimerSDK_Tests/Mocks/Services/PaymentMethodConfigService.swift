//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
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
