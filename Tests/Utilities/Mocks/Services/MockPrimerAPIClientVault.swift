//
//  MockPrimerAPIClientVault.swift
//
//
//  Created by Onur Var on 8.06.2025.
//

@testable import PrimerSDK

class MockPrimerAPIClientVault: PrimerAPIClientVaultProtocol {
    var onFetchVaultedPaymentMethods: ((DecodedJWTToken) -> Response.Body.VaultedPaymentMethods)?

    func fetchVaultedPaymentMethods(clientToken: DecodedJWTToken, completion: @escaping APICompletion<Response.Body.VaultedPaymentMethods>) {
        if let result = onFetchVaultedPaymentMethods?(clientToken) {
            completion(.success(result))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }

    func fetchVaultedPaymentMethods(clientToken: PrimerSDK.DecodedJWTToken) async throws -> PrimerSDK.Response.Body.VaultedPaymentMethods {
        if let result = onFetchVaultedPaymentMethods?(clientToken) {
            return result
        } else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
    }

    var onDeleteVaultedPaymentMethods: ((DecodedJWTToken, String) -> Void)?

    func deleteVaultedPaymentMethod(clientToken: DecodedJWTToken, id: String, completion: @escaping APICompletion<Void>) {
        if let onDeleteVaultedPaymentMethods = onDeleteVaultedPaymentMethods {
            onDeleteVaultedPaymentMethods(clientToken, id)
            completion(.success(()))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }

    func deleteVaultedPaymentMethod(clientToken: PrimerSDK.DecodedJWTToken, id: String) async throws {
        if let onDeleteVaultedPaymentMethods = onDeleteVaultedPaymentMethods {
            onDeleteVaultedPaymentMethods(clientToken, id)
        } else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
    }
}
