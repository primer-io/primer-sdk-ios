//
//  PrimerAPIClient.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation

extension PrimerAPIClient {

    func tokenizePaymentMethod(clientToken: DecodedJWTToken,
                               tokenizationRequestBody: Request.Body.Tokenization,
                               completion: @escaping (_ result: Result<PrimerPaymentMethodTokenData, Error>) -> Void) {

        let endpoint = PrimerAPI.tokenizePaymentMethod(clientToken: clientToken,
                                                       tokenizationRequestBody: tokenizationRequestBody)
        networkService.request(endpoint) { (result: Result<PrimerPaymentMethodTokenData, Error>) in
            switch result {
            case .success(let paymentMethodToken):
                completion(.success(paymentMethodToken))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
}
