//
//  PrimerAPIClient+3DS.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 2/4/21.
//

import Foundation

extension PrimerAPIClient {
    
    func threeDSBeginAuth(clientToken: DecodedClientToken, paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.threeDSBeginRemoteAuth(clientToken: clientToken, paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest)
        networkService.request(endpoint) { (result: Result<ThreeDS.BeginAuthResponse, NetworkServiceError>) in
            switch result {
            case .success(let threeDSecureBeginAuthResponse):
                completion(.success(threeDSecureBeginAuthResponse))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.threeDSFailed))
            }
        }
    }
    
    func threeDSContinueAuth(clientToken: DecodedClientToken, threeDSTokenId: String, completion: @escaping (_ result: Result<ThreeDS.PostAuthResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.threeDSContinueRemoteAuth(clientToken: clientToken, threeDSTokenId: threeDSTokenId)
        networkService.request(endpoint) { (result: Result<ThreeDS.PostAuthResponse, NetworkServiceError>) in
            switch result {
            case .success(let postAuthResponse):
                completion(.success(postAuthResponse))
                
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.tokenizationRequestFailed))
            }
        }
        
    }
    
}

extension MockPrimerAPIClient {
    
    func threeDSBeginAuth(clientToken: DecodedClientToken, paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
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
    
    func threeDSContinueAuth(clientToken: DecodedClientToken, threeDSTokenId: String, completion: @escaping (Result<ThreeDS.PostAuthResponse, Error>) -> Void) {
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
