//
//  PrimerAPIClient+3DS.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 2/4/21.
//

import Foundation

extension PrimerAPIClient {
    func begin3DSAuth(clientToken: DecodedJWTToken,
                      paymentMethodTokenData: PrimerPaymentMethodTokenData,
                      threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest,
                      completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.begin3DSRemoteAuth(clientToken: clientToken,
                                                    paymentMethodTokenData: paymentMethodTokenData,
                                                    threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest)
        networkService.request(endpoint) { (result: Result<ThreeDS.BeginAuthResponse, Error>) in
            switch result {
            case let .success(threeDSecureBeginAuthResponse):
                completion(.success(threeDSecureBeginAuthResponse))
            case let .failure(err):
                completion(.failure(err))
            }
        }
    }

    func begin3DSAuth(
        clientToken: DecodedJWTToken,
        paymentMethodTokenData: PrimerPaymentMethodTokenData,
        threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest
    ) async throws -> ThreeDS.BeginAuthResponse {
        try await awaitResult { completion in
            self.begin3DSAuth(clientToken: clientToken,
                              paymentMethodTokenData: paymentMethodTokenData,
                              threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest,
                              completion: completion
            )
        }
    }

    func continue3DSAuth(clientToken: DecodedJWTToken,
                         threeDSTokenId: String,
                         continueInfo: ThreeDS.ContinueInfo,
                         completion: @escaping (_ result: Result<ThreeDS.PostAuthResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.continue3DSRemoteAuth(clientToken: clientToken,
                                                       threeDSTokenId: threeDSTokenId,
                                                       continueInfo: continueInfo)
        networkService.request(endpoint) { (result: Result<ThreeDS.PostAuthResponse, Error>) in
            switch result {
            case let .success(postAuthResponse):
                completion(.success(postAuthResponse))

            case let .failure(err):
                completion(.failure(err))
            }
        }
    }

    func continue3DSAuth(
        clientToken: DecodedJWTToken,
        threeDSTokenId: String,
        continueInfo: ThreeDS.ContinueInfo
    ) async throws -> ThreeDS.PostAuthResponse {
        try await awaitResult { completion in
            self.continue3DSAuth(clientToken: clientToken,
                                 threeDSTokenId: threeDSTokenId,
                                 continueInfo: continueInfo,
                                 completion: completion)
        }
    }
}
