//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)
#if canImport(Primer3DS)
import Foundation

extension ThreeDSService {
    
    func beginRemoteAuth(paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest) -> Promise<ThreeDS.BeginAuthResponse> {
        return Promise { seal in
            self.beginRemoteAuth(paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest) { result in
                switch result {
                case .success(let transaction):
                    seal.fulfill(transaction)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
    
    func continueRemoteAuth(threeDSTokenId: String) -> Promise<ThreeDS.PostAuthResponse> {
        return Promise { seal in
            self.continueRemoteAuth(threeDSTokenId: threeDSTokenId) { result in
                switch result {
                case .success(let postAuthResponse):
                    seal.fulfill(postAuthResponse)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
    
}

#endif
#endif
