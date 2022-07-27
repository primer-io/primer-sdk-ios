//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
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

        XCTAssertEqual(vaultService.loadVaultedPaymentMethodsCalled, true)
    }

    func test_deletePaymentMethod_calls_vaultService_deleteVaultedPaymentMethod() throws {
        let clientTokenService = MockClientTokenService()
        let vaultService = MockVaultService()

        MockLocator.registerDependencies()
        DependencyContainer.register(clientTokenService as ClientTokenServiceProtocol)
        DependencyContainer.register(vaultService as VaultServiceProtocol)

        let viewModel = VaultPaymentMethodViewModel()

        viewModel.deletePaymentMethod(with: "id", and: { _ in })

        XCTAssertEqual(vaultService.deleteVaultedPaymentMethodCalled, true)
    }
}

#endif
