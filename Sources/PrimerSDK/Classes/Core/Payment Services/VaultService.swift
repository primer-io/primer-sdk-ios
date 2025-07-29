//
//  VaultService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

internal protocol VaultServiceProtocol {
    func fetchVaultedPaymentMethods() -> Promise<Void>
    func fetchVaultedPaymentMethods() async throws
    func deleteVaultedPaymentMethod(with id: String) -> Promise<Void>
    func deleteVaultedPaymentMethod(with id: String) async throws
}

final class VaultService: VaultServiceProtocol {

    let apiClient: PrimerAPIClientVaultProtocol

    init(apiClient: PrimerAPIClientVaultProtocol) {
        self.apiClient = apiClient
    }

    func fetchVaultedPaymentMethods() -> Promise<Void> {
        return Promise { seal in
            let state: AppStateProtocol = AppState.current

            guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                return seal.reject(handled(primerError: .invalidClientToken()))
            }

            firstly {
                fetchVaultedPaymentMethods(clientToken: clientToken)
            }
            .done { paymentMethods in
                state.paymentMethods = paymentMethods.data
                state.selectedPaymentMethodId = paymentMethods.data.first?.id
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    func fetchVaultedPaymentMethods() async throws {
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw handled(primerError: .invalidClientToken())
        }

        let state: AppStateProtocol = AppState.current
        let paymentMethods = try await apiClient.fetchVaultedPaymentMethods(clientToken: clientToken)
        state.paymentMethods = paymentMethods.data
        state.selectedPaymentMethodId = paymentMethods.data.first?.id
    }

    func fetchVaultedPaymentMethods(clientToken: DecodedJWTToken) -> Promise<Response.Body.VaultedPaymentMethods> {
        return Promise { seal in
            apiClient.fetchVaultedPaymentMethods(clientToken: clientToken, completion: { result in
                switch result {
                case .success(let response):
                    seal.fulfill(response)
                case .failure(let err):
                    seal.reject(err)
                }
            })
        }
    }

    func deleteVaultedPaymentMethod(with id: String) -> Promise<Void> {
        return Promise { seal in
            guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                return seal.reject(handled(primerError: .invalidClientToken()))
            }

            apiClient.deleteVaultedPaymentMethod(clientToken: clientToken, id: id) { (result) in
                switch result {
                case .failure(let err): seal.reject(handled(primerError: .failedToCreateSession(error: err)))
                case .success: seal.fulfill()
                }
            }
        }
    }

    func deleteVaultedPaymentMethod(with id: String) async throws {
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw handled(primerError: .invalidClientToken())
        }

        do {
            try await apiClient.deleteVaultedPaymentMethod(clientToken: clientToken, id: id)
        } catch {
            throw handled(primerError: .failedToCreateSession(error: error))
        }
    }
}
