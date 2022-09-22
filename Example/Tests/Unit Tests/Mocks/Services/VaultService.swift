//
//  VaultService.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockVaultService: VaultServiceProtocol {
    
    func fetchVaultedPaymentMethods() -> Promise<Void> {
        return Promise()
    }
    
    func deleteVaultedPaymentMethod(with id: String) -> Promise<Void> {
        return Promise()
    }
}

#endif
