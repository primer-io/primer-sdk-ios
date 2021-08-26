//
//  3DSService+Promises.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/21.
//

#if canImport(ThreeDS_SDK)
import Foundation
import ThreeDS_SDK

extension ThreeDSService {
    
    func initializeSDK(_ sdk: ThreeDSSDKProtocol) -> Promise<Void> {
        return Promise { seal in
            self.initializeSDK(sdk) { result in
                switch result {
                case .success:
                    seal.fulfill(())
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
    
    func authenticateSdk(sdk: ThreeDSSDKProtocol,
                         cardNetwork: CardNetwork,
                         protocolVersion: ThreeDS.ProtocolVersion) -> Promise<Transaction> {
        return Promise { seal in
            self.authenticateSdk(sdk: sdk, cardNetwork: cardNetwork, protocolVersion: protocolVersion) { result in
                switch result {
                case .success(let transaction):
                    seal.fulfill(transaction)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
    
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
    
    func performChallenge(with sdk: ThreeDSSDKProtocol,
                          on transaction: Transaction,
                          threeDSAuth: ThreeDSAuthenticationProtocol,
                          presentOn viewController: UIViewController) -> Promise<ThreeDS.ThreeDSSDKAuthCompletion>
    {
        return Promise { seal in
            self.performChallenge(with: sdk, on: transaction, threeDSAuth: threeDSAuth, presentOn: viewController) { result in
                switch result {
                case .success(let sdkAuth):
                    seal.fulfill(sdkAuth)
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
