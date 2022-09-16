//
//  VaultPaymentMethodViewModelTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 07/01/2021.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class VaultPaymentMethodViewModelTests: XCTestCase {

    func test_reloadVault_calls_vaultService_loadVaultedPaymentMethods() throws {
        let clientTokenService = MockClientTokenService()
        let vaultService = MockVaultService()

        MockLocator.registerDependencies()
        DependencyContainer.register(clientTokenService as ClientTokenServiceProtocol)
        DependencyContainer.register(vaultService as VaultServiceProtocol)

        let viewModel = VaultPaymentMethodViewModel()

        viewModel.reloadVault(with: { _ in })
    }

    func test_deletePaymentMethod_calls_vaultService_deleteVaultedPaymentMethod() throws {
        let clientTokenService = MockClientTokenService()
        let vaultService = MockVaultService()

        MockLocator.registerDependencies()
        DependencyContainer.register(clientTokenService as ClientTokenServiceProtocol)
        DependencyContainer.register(vaultService as VaultServiceProtocol)

        let viewModel = VaultPaymentMethodViewModel()

        viewModel.deletePaymentMethod(with: "id", and: { _ in })
    }
}

#endif
