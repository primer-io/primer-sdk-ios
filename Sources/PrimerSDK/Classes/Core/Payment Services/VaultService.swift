//
//  VaultService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

internal protocol VaultServiceProtocol {
    func fetchVaultedPaymentMethods() async throws
    func deleteVaultedPaymentMethod(with id: String) async throws
}

final class VaultService: VaultServiceProtocol {
    let apiClient: PrimerAPIClientVaultProtocol

    init(apiClient: PrimerAPIClientVaultProtocol) {
        self.apiClient = apiClient
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
