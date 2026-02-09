//
//  MockBanksAPIClient.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerNetworking
@testable import PrimerSDK

final class MockBanksAPIClient: PrimerAPIClientBanksProtocol {

    var result: BanksListSessionResponse?

    var error: Error?

    func listAdyenBanks(clientToken: PrimerSDK.DecodedJWTToken, request: Request.Body.Adyen.BanksList, completion: @escaping PrimerSDK.APICompletion<BanksListSessionResponse>) {
        if let error = error {
            completion(.failure(error))
        } else if let result = result {
            completion(.success(result))
        }
    }

    func listAdyenBanks(clientToken: PrimerSDK.DecodedJWTToken, request: Request.Body.Adyen.BanksList) async throws -> BanksListSessionResponse {
        if let error { throw error }
        if let result { return result }
        throw PrimerError.unknown()
    }
}
