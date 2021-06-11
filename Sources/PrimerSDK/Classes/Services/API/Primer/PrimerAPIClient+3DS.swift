//
//  PrimerAPIClient+3DS.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 2/4/21.
//

import Foundation

extension PrimerAPIClient {
    
    func threeDSecureBeginAuthentication(clientToken: DecodedClientToken, paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.threeDSecureBeginAuthentication(clientToken: clientToken, paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest)
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
    
    func threeDSecureStatus(clientToken: DecodedClientToken, url: String, completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.threeDSecureStatus(clientToken: clientToken, url: url)
        networkService.request(endpoint) { (result: Result<ThreeDS.BeginAuthResponse, NetworkServiceError>) in
            switch result {
            case .success(let authResponse):
                print(authResponse)
                Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { (_) in
                    self.threeDSecureStatus(clientToken: clientToken, url: url, completion: completion)
                }
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.tokenizationRequestFailed))
            }
        }
    }
    
    func threeDSecurePostAuthentication(clientToken: DecodedClientToken, threeDSTokenId: String, completion: @escaping (_ result: Result<ThreeDS.PostAuthResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.threeDSecurePostAuthentication(clientToken: clientToken, threeDSTokenId: threeDSTokenId)
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
    
    func threeDSecureBeginAuthentication(clientToken: DecodedClientToken, paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(ThreeDS.BeginAuthResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
}
