//
//  PrimerAPIClient+3DS.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 2/4/21.
//

#if canImport(UIKit)

import Foundation

extension PrimerAPIClient {
    
    func begin3DSAuth(clientToken: DecodedClientToken, paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.begin3DSRemoteAuth(clientToken: clientToken, paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest)
        networkService.request(endpoint) { (result: Result<ThreeDS.BeginAuthResponse, Error>) in
            switch result {
            case .success(let threeDSecureBeginAuthResponse):
                completion(.success(threeDSecureBeginAuthResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func continue3DSAuth(clientToken: DecodedClientToken, threeDSTokenId: String, completion: @escaping (_ result: Result<ThreeDS.PostAuthResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.continue3DSRemoteAuth(clientToken: clientToken, threeDSTokenId: threeDSTokenId)
        networkService.request(endpoint) { (result: Result<ThreeDS.PostAuthResponse, Error>) in
            switch result {
            case .success(let postAuthResponse):
                completion(.success(postAuthResponse))
                
            case .failure(let err):
                completion(.failure(err))
            }
        }
        
    }
    
}

extension MockPrimerAPIClient {
    
    func begin3DSAuth(clientToken: DecodedClientToken, paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        do {
            let value = try JSONDecoder().decode(ThreeDS.BeginAuthResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
    func continue3DSAuth(clientToken: DecodedClientToken, threeDSTokenId: String, completion: @escaping (Result<ThreeDS.PostAuthResponse, Error>) -> Void) {
        isCalled = true
        
        guard let response = response else {
            let nsErr = NSError(domain: "mock", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mocked response needs to be set"])
            completion(.failure(nsErr))
            return
        }
        
        do {
            let value = try JSONDecoder().decode(ThreeDS.PostAuthResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
}

#endif
