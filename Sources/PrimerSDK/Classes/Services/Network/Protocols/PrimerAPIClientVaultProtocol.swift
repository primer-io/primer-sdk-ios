//
//  PrimerAPIClientVaultProtocol.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 24/05/2024.
//

import Foundation

protocol PrimerAPIClientVaultProtocol {
    // MARK: Vault

    func fetchVaultedPaymentMethods(
        clientToken: DecodedJWTToken,
        completion: @escaping APICompletion<Response.Body.VaultedPaymentMethods>)

    func deleteVaultedPaymentMethod(
        clientToken: DecodedJWTToken,
        id: String,
        completion: @escaping APICompletion<Void>)
}
