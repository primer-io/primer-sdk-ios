//
//  PrimerAPIClient+PCI.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerNetworking

extension PrimerAPIClient {

    func tokenizePaymentMethod(clientToken: DecodedJWTToken,
                               tokenizationRequestBody: Request.Body.Tokenization,
                               completion: @escaping (_ result: Result<PrimerPaymentMethodTokenData, Error>) -> Void) {

        let endpoint = PrimerAPI.tokenizePaymentMethod(clientToken: clientToken,
                                                       tokenizationRequestBody: tokenizationRequestBody)
        networkService.request(endpoint) { (result: Result<PrimerPaymentMethodTokenData, Error>) in
            switch result {
            case let .success(paymentMethodToken):
                completion(.success(paymentMethodToken))
            case let .failure(err):
                completion(.failure(err))
            }
        }
    }

    func tokenizePaymentMethod(
        clientToken: DecodedJWTToken,
        tokenizationRequestBody: Request.Body.Tokenization
    ) async throws -> PrimerPaymentMethodTokenData {
        let endpoint = PrimerAPI.tokenizePaymentMethod(clientToken: clientToken,
                                                       tokenizationRequestBody: tokenizationRequestBody)
        return try await networkService.request(endpoint)
    }
}
