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
        
        let settings = PrimerSettings(
            amount: 200,
            currency: .EUR,
            clientTokenRequestCallback: { completion in },
            onTokenizeSuccess: { (result, callback) in },
            theme: PrimerTheme(),
            uxMode: .CHECKOUT,
            applePayEnabled: false,
            customerId: "cid",
            merchantIdentifier: "mid",
            countryCode: .FR
        )
        
        let clientTokenService = MockClientTokenService()
        let vaultService = MockVaultService()
        let cardFormViewModel = MockCardFormViewModel()
        
        let viewModel = VaultPaymentMethodViewModel(
            with: clientTokenService,
            and: vaultService,
            and: cardFormViewModel,
            and: settings
        )
        
        viewModel.reloadVault(with: { error in })
        
        XCTAssertEqual(vaultService.loadVaultedPaymentMethodsCalled, true)
    }
    
    func test_deletePaymentMethod_calls_vaultService_deleteVaultedPaymentMethod() throws {
        let settings = PrimerSettings(
            amount: 200,
            currency: .EUR,
            clientTokenRequestCallback: { completion in },
            onTokenizeSuccess: { (result, callback) in },
            theme: PrimerTheme(),
            uxMode: .CHECKOUT,
            applePayEnabled: false,
            customerId: "cid",
            merchantIdentifier: "mid",
            countryCode: .FR
        )
        
        let clientTokenService = MockClientTokenService()
        let vaultService = MockVaultService()
        let cardFormViewModel = MockCardFormViewModel()
        
        let viewModel = VaultPaymentMethodViewModel(
            with: clientTokenService,
            and: vaultService,
            and: cardFormViewModel,
            and: settings
        )
        
        viewModel.deletePaymentMethod(with: "id", and: { error in })
        
        XCTAssertEqual(vaultService.deleteVaultedPaymentMethodCalled, true)
    }
}
