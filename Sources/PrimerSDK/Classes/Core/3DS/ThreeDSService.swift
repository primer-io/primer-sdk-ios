//
//  ThreeDSService.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 17/6/21.
//

import Foundation
import ThreeDS_SDK

protocol ThreeDSServiceProtocol {
    func initializeSDK(_ sdk: ThreeDSSDKProtocol, completion: @escaping (Result<Void, Error>) -> Void)
    func sdkAuth(sdk: ThreeDSSDKProtocol,
                 cardNetwork: CardNetwork,
                 protocolVersion: ThreeDS.ProtocolVersion,
                 completion: @escaping (Result<Transaction, Error>) -> Void)
    func beginRemoteAuth(paymentMethodToken: PaymentMethodToken,
                         threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest,
                         completion: @escaping (Result<ThreeDS.BeginAuthResponse, Error>) -> Void)
    func performChallenge(with sdk: ThreeDSSDKProtocol,
                          on transaction: Transaction,
                          with threeDSecureAuthResponse: ThreeDSAuthenticationProtocol,
                          presentOn viewController: UIViewController,
                          completion: @escaping (Result<ThreeDS.ThreeDSSDKAuthCompletion, Error>) -> Void)
    func continueRemoteAuth(threeDSTokenId: String, completion: @escaping (Result<ThreeDS.PostAuthResponse, Error>) -> Void)
}

class ThreeDSService: ThreeDSServiceProtocol {
        
    deinit {
        print("ThreeDSecureServiceProtocol deinit")
    }
    
    func initializeSDK(_ sdk: ThreeDSSDKProtocol, completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.initializeSDK(completion: completion)
    }
    
    func sdkAuth(sdk: ThreeDSSDKProtocol,
                 cardNetwork: CardNetwork,
                 protocolVersion: ThreeDS.ProtocolVersion,
                 completion: @escaping (Result<Transaction, Error>) -> Void) {
        sdk.sdkAuth(cardNetwork: cardNetwork, protocolVersion: protocolVersion, completion: completion)
    }
    
    func beginRemoteAuth(paymentMethodToken: PaymentMethodToken,
                         threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest,
                         completion: @escaping (Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(PrimerError.vaultFetchFailed))
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        
        api.threeDSecureBeginAuthentication(clientToken: clientToken, paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest, completion: { result in
            switch result {
            case .failure(let err):
                completion(.failure(err))
            case .success(let res):
                completion(.success(res))
            }
        })
    }
    
    func performChallenge(with sdk: ThreeDSSDKProtocol,
                          on transaction: Transaction,
                          with threeDSecureAuthResponse: ThreeDSAuthenticationProtocol,
                          presentOn viewController: UIViewController,
                          completion: @escaping (Result<ThreeDS.ThreeDSSDKAuthCompletion, Error>) -> Void) {
        sdk.performChallenge(on: transaction,
                             with: threeDSecureAuthResponse,
                             presentOn: viewController,
                             completion: completion)
    }
    
    func continueRemoteAuth(threeDSTokenId: String, completion: @escaping (Result<ThreeDS.PostAuthResponse, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(PrimerError.vaultFetchFailed))
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        api.threeDSecurePostAuthentication(clientToken: clientToken, threeDSTokenId: threeDSTokenId) { result in
            switch result {
            case .failure(let err):
                completion(.failure(err))
            case .success(let res):
                completion(.success(res))
            }
        }
    }
    
}
