//
//  VaultPaymentMethodViewModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

internal protocol VaultPaymentMethodViewModelProtocol: AnyObject {
    var paymentMethods: [PrimerPaymentMethodTokenData] { get }
    var selectedPaymentMethodId: String? { get set }
    func reloadVault(with completion: @escaping (Error?) -> Void)
    func deletePaymentMethod(with id: String, and completion: @escaping (Error?) -> Void)
}

final class VaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol {

    let vaultService: VaultServiceProtocol

    init(vaultService: VaultServiceProtocol = VaultService(apiClient: PrimerAPIClient())) {
        self.vaultService = vaultService
    }

    var paymentMethods: [PrimerPaymentMethodTokenData] {
        return AppState.current.paymentMethods
    }
    var selectedPaymentMethodId: String? {
        get {
            return AppState.current.selectedPaymentMethodId
        }
        set {
            AppState.current.selectedPaymentMethodId = newValue
        }
    }

    func reloadVault(with completion: @escaping (Error?) -> Void) {
        Task {
            do {
                try await vaultService.fetchVaultedPaymentMethods()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    func deletePaymentMethod(with paymentMethodToken: String, and completion: @escaping (Error?) -> Void) {
        Task {
            do {
                try await vaultService.deleteVaultedPaymentMethod(with: paymentMethodToken)

                if paymentMethodToken == AppState.current.selectedPaymentMethodId {
                    AppState.current.selectedPaymentMethodId = nil
                }

                try await vaultService.fetchVaultedPaymentMethods()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}
