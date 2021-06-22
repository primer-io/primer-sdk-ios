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
        
        api.threeDSBeginAuth(clientToken: clientToken, paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest, completion: { result in
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
        api.threeDSContinueAuth(clientToken: clientToken, threeDSTokenId: threeDSTokenId) { result in
            switch result {
            case .failure(let err):
                completion(.failure(err))
            case .success(let res):
                completion(.success(res))
            }
        }
    }
    
}

class MockThreeDSService: ThreeDSServiceProtocol {
    
    var response: Data?
    let throwsError: Bool = false
    var isCalled: Bool = false
    
    init(with response: Data? = nil) {
        self.response = response
    }
    
    func initializeSDK(_ sdk: ThreeDSSDKProtocol, completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.initializeSDK(completion: completion)
    }
    
    func sdkAuth(sdk: ThreeDSSDKProtocol, cardNetwork: CardNetwork, protocolVersion: ThreeDS.ProtocolVersion, completion: @escaping (Result<Transaction, Error>) -> Void) {
        sdk.sdkAuth(cardNetwork: cardNetwork, protocolVersion: protocolVersion, completion: completion)
    }
    
    func beginRemoteAuth(paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(PrimerError.vaultFetchFailed))
        }
        
        let api = MockPrimerAPIClient()
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        api.response = response
        
        api.threeDSBeginAuth(clientToken: clientToken, paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest, completion: completion)
    }
    
    func performChallenge(with sdk: ThreeDSSDKProtocol, on transaction: Transaction, with threeDSecureAuthResponse: ThreeDSAuthenticationProtocol, presentOn viewController: UIViewController, completion: @escaping (Result<ThreeDS.ThreeDSSDKAuthCompletion, Error>) -> Void) {
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            do {
                let authCompletion = ThreeDS.ThreeDSSDKAuthCompletion(sdkTransactionId: "transaction_id", transactionStatus: .y)
                completion(.success(authCompletion))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func continueRemoteAuth(threeDSTokenId: String, completion: @escaping (Result<ThreeDS.PostAuthResponse, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(PrimerError.vaultFetchFailed))
        }
        
        let api = MockPrimerAPIClient()
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        api.response = response
        
        api.threeDSContinueAuth(clientToken: clientToken, threeDSTokenId: threeDSTokenId, completion: completion)
    }
}
