//
//  PrimerAPIClientXenditProtocol.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 10/06/2024.
//

import Foundation

protocol PrimerAPIClientXenditProtocol {

    // MARK: Xendit Retail Outlets

    func listRetailOutlets(
        clientToken: DecodedJWTToken,
        paymentMethodId: String,
        completion: @escaping APICompletion<RetailOutletsList>)

    func listRetailOutlets(
        clientToken: DecodedJWTToken,
        paymentMethodId: String
    ) async throws -> RetailOutletsList
}
