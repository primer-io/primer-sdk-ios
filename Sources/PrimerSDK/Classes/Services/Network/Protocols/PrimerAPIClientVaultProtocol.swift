//
//  PrimerAPIClientVaultProtocol.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol PrimerAPIClientVaultProtocol {
    // MARK: Vault

    func fetchVaultedPaymentMethods(
        clientToken: DecodedJWTToken,
        completion: @escaping APICompletion<Response.Body.VaultedPaymentMethods>)

    func fetchVaultedPaymentMethods(
        clientToken: DecodedJWTToken
    ) async throws -> Response.Body.VaultedPaymentMethods

    func deleteVaultedPaymentMethod(
        clientToken: DecodedJWTToken,
        id: String,
        completion: @escaping APICompletion<Void>)

    func deleteVaultedPaymentMethod(
        clientToken: DecodedJWTToken,
        id: String
    ) async throws
}
