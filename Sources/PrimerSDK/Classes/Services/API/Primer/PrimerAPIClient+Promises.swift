//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import Foundation

extension PrimerAPIClient {
    
    func fetchVaultedPaymentMethods(clientToken: DecodedClientToken) -> Promise<GetVaultedPaymentMethodsResponse> {
        return Promise { [weak self] seal in
            self?.fetchVaultedPaymentMethods(clientToken: clientToken, completion: { result in
                switch result {
                case .success(let response):
                    seal.fulfill(response)
                case .failure(let err):
                    seal.reject(err)
                }
            })
        }
    }
    
}

#endif
