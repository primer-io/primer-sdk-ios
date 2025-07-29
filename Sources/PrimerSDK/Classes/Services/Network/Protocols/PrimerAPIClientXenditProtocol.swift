//
//  PrimerAPIClientXenditProtocol.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

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
