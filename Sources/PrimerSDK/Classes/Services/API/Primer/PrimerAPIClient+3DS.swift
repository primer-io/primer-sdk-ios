//
//  PrimerAPIClient+3DS.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 2/4/21.
//

import Foundation

extension PrimerAPIClient {
    
    func threeDSecureBeginAuthentication(clientToken: DecodedClientToken, paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDSecureBeginAuthRequest, completion: @escaping (_ result: Result<ThreeDSecureBeginAuthResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.threeDSecureBeginAuthentication(clientToken: clientToken, paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest)
        networkService.request(endpoint) { (result: Result<ThreeDSecureBeginAuthResponse, NetworkServiceError>) in
            switch result {
            case .success(let threeDSecureBeginAuthResponse):
                completion(.success(threeDSecureBeginAuthResponse))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(PrimerError.threeDSFailed))
            }
        }
    }
    
}

extension MockPrimerAPIClient {
    
    func threeDSecureBeginAuthentication(clientToken: DecodedClientToken, paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDSecureBeginAuthRequest, completion: @escaping (_ result: Result<ThreeDSecureBeginAuthResponse, Error>) -> Void) {
        isCalled = true
        guard let response = response else { return }

        do {
            let value = try JSONDecoder().decode(ThreeDSecureBeginAuthResponse.self, from: response)
            completion(.success(value))
        } catch {
            completion(.failure(error))
        }
    }
    
}
