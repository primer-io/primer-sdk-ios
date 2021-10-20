//
//  PrimerAPIClient+Promises.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 15/6/21.
//

#if canImport(UIKit)

import Foundation

extension PrimerAPIClient {
    
    func vaultFetchPaymentMethods(clientToken: DecodedClientToken) -> Promise<GetVaultedPaymentMethodsResponse> {
        return Promise { [weak self] seal in
            self?.vaultFetchPaymentMethods(clientToken: clientToken, completion: { result in
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
