//
//  MockPrimerAPIClientVault.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK

final class MockPrimerAPIClientVault: PrimerAPIClientVaultProtocol {

    var onFetchVaultedPaymentMethods: ((DecodedJWTToken) -> Response.Body.VaultedPaymentMethods)?
    var onDeleteVaultedPaymentMethods: ((DecodedJWTToken, String) -> Void)?

    func fetchVaultedPaymentMethods(clientToken: DecodedJWTToken, completion: @escaping APICompletion<Response.Body.VaultedPaymentMethods>) {
        if let result = onFetchVaultedPaymentMethods?(clientToken) {
            completion(.success(result))
        } else {
            completion(.failure(PrimerError.unknown()))
        }
    }

    func fetchVaultedPaymentMethods(clientToken: DecodedJWTToken) async throws -> Response.Body.VaultedPaymentMethods {
        if let result = onFetchVaultedPaymentMethods?(clientToken) {
            return result
        } else {
            throw PrimerError.unknown()
        }
    }

    func deleteVaultedPaymentMethod(clientToken: DecodedJWTToken, id: String, completion: @escaping APICompletion<Void>) {
        if let onDeleteVaultedPaymentMethods = onDeleteVaultedPaymentMethods {
            onDeleteVaultedPaymentMethods(clientToken, id)
            completion(.success(()))
        } else {
            completion(.failure(PrimerError.unknown()))
        }
    }

    func deleteVaultedPaymentMethod(clientToken: DecodedJWTToken, id: String) async throws {
        if let onDeleteVaultedPaymentMethods = onDeleteVaultedPaymentMethods {
            onDeleteVaultedPaymentMethods(clientToken, id)
        } else {
            throw PrimerError.unknown()
        }
    }
}
