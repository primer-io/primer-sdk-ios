//
//  MockXenditAPIClient.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
@testable import PrimerSDK

final class MockXenditAPIClient: PrimerAPIClientXenditProtocol {

    var onListRetailOutlets: ((DecodedJWTToken, String) -> RetailOutletsList)?

    func listRetailOutlets(clientToken: DecodedJWTToken, paymentMethodId: String, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.RetailOutletsList>) {
        if let onListRetailOutlets = onListRetailOutlets {
            completion(.success(onListRetailOutlets(clientToken, paymentMethodId)))
        } else {
            completion(.failure(PrimerError.unknown()))
        }
    }

    func listRetailOutlets(clientToken: DecodedJWTToken, paymentMethodId: String) async throws -> RetailOutletsList {
        if let onListRetailOutlets = onListRetailOutlets {
            return onListRetailOutlets(clientToken, paymentMethodId)
        } else {
            throw PrimerError.unknown()
        }
    }
}
