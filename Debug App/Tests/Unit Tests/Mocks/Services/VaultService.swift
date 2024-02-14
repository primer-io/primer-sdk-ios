//
//  VaultService.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

@testable import PrimerSDK

class MockVaultService: VaultServiceProtocol {

    static var apiClient: PrimerAPIClientProtocol?

    func fetchVaultedPaymentMethods() -> Promise<Void> {
        return Promise()
    }

    func deleteVaultedPaymentMethod(with id: String) -> Promise<Void> {
        return Promise()
    }
}
