//
//  PrimerAPIClient+3DS.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerCore
import PrimerNetworking

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
        try await networkService.request(
            PrimerAPI.begin3DSRemoteAuth(
                clientToken: clientToken,
                paymentMethodTokenData: paymentMethodTokenData,
                threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest
            )
        )
    }

    func continue3DSAuth(
        clientToken: DecodedJWTToken,
        threeDSTokenId: String,
        continueInfo: ThreeDS.ContinueInfo,
        completion: @escaping (_ result: Result<ThreeDS.PostAuthResponse, Error>) -> Void
    ) {
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
        try await networkService.request(
            PrimerAPI.continue3DSRemoteAuth(clientToken: clientToken,
                                            threeDSTokenId: threeDSTokenId,
                                            continueInfo: continueInfo)
        )
    }
}
