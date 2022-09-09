//
//  3DSService+Promises.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/21.
//

#if canImport(UIKit)
#if canImport(Primer3DS)
import Foundation

extension ThreeDSService {
    
    func beginRemoteAuth(paymentMethodTokenData: PrimerPaymentMethodTokenData, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest) -> Promise<ThreeDS.BeginAuthResponse> {
        return Promise { seal in
            self.beginRemoteAuth(paymentMethodTokenData: paymentMethodTokenData, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest) { result in
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
