//
//  PrimerAPIClientBanksProtocol.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol PrimerAPIClientBanksProtocol {
    func listAdyenBanks(
        clientToken: DecodedJWTToken,
        request: Request.Body.Adyen.BanksList,
        completion: @escaping APICompletion<BanksListSessionResponse>)

    func listAdyenBanks(
        clientToken: DecodedJWTToken,
        request: Request.Body.Adyen.BanksList
    ) async throws -> BanksListSessionResponse
}
