//
//  VaultPaymentMethodViewModelTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 07/01/2021.
//

import XCTest
@testable import PrimerSDK

class VaultPaymentMethodViewModelTests: XCTestCase {
    
    func test_reloadVault_calls_vaultService_loadVaultedPaymentMethods() throws {
        let clientTokenService = MockClientTokenService()
        let vaultService = MockVaultService()
        let serviceLocator = MockServiceLocator(clientTokenService: clientTokenService, vaultService: vaultService)
        let context = MockCheckoutContext(serviceLocator: serviceLocator)
        
        let viewModel = VaultPaymentMethodViewModel(context: context)
        
        viewModel.reloadVault(with: { error in })
        
        XCTAssertEqual(vaultService.loadVaultedPaymentMethodsCalled, true)
    }
    
    func test_deletePaymentMethod_calls_vaultService_deleteVaultedPaymentMethod() throws {
        let clientTokenService = MockClientTokenService()
        let vaultService = MockVaultService()
        let serviceLocator = MockServiceLocator(clientTokenService: clientTokenService, vaultService: vaultService)
        let context = MockCheckoutContext(serviceLocator: serviceLocator)
        
        let viewModel = VaultPaymentMethodViewModel(context: context)
        
        viewModel.deletePaymentMethod(with: "id", and: { error in })
        
        XCTAssertEqual(vaultService.deleteVaultedPaymentMethodCalled, true)
    }
}
