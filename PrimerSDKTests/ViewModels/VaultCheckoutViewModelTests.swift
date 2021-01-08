//
//  PrimerSDKTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 07/12/2020.
//

import XCTest
@testable import PrimerSDK

class VaultCheckoutViewModelTests: XCTestCase {

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func test_loadConfig_calls_clientTokenService() throws {
        
        let clientTokenService = MockClientTokenService()
        let vaultPaymentMethodViewModel = MockVaultPaymentMethodViewModel()
        let applePayViewModel = MockApplePayViewModel()
        let vaultService = MockVaultService()
        
        let viewModel = VaultCheckoutViewModel(
            with: clientTokenService,
            and: vaultPaymentMethodViewModel,
            and: applePayViewModel,
            and: vaultService,
            and: mockSettings
        )
        
        viewModel.loadConfig({ error in })
        
        XCTAssertEqual(clientTokenService.loadCheckoutConfigCalled, true)
    }
    
    func test_VaultCheckoutViewModel_authorizePayment_calls_settings_onTokenizeSuccess() throws {
        
        var onTokenizeSuccessCalled = false
        
        let settings = PrimerSettings(
            amount: 200,
            currency: .EUR,
            clientTokenRequestCallback: { completion in },
            onTokenizeSuccess: { (result, callback) in
                onTokenizeSuccessCalled = true
            },
            theme: PrimerTheme(),
            uxMode: .CHECKOUT,
            applePayEnabled: false,
            customerId: "cid",
            merchantIdentifier: "mid",
            countryCode: .FR
        )
        
        let paymentMethodConfigService = MockPaymentMethodConfigService()
        let clientTokenService = MockClientTokenService()
        let vaultPaymentMethodViewModel = MockVaultPaymentMethodViewModel()
        let applePayViewModel = MockApplePayViewModel()
        let vaultService = MockVaultService()
        
        let viewModel = VaultCheckoutViewModel(
            with: clientTokenService,
            and: vaultPaymentMethodViewModel,
            and: applePayViewModel,
            and: vaultService,
            and: settings
        )
        
        viewModel.authorizePayment({ error in })
        
        XCTAssertEqual(onTokenizeSuccessCalled, true)
    }
    
    func test_authorizePayment_does_not_call_onTokenizeSuccess_when_payment_methods_empty() throws {
        var onTokenizeSuccessCalled = false
        
        let settings = PrimerSettings(
            amount: 200,
            currency: .EUR,
            clientTokenRequestCallback: { completion in },
            onTokenizeSuccess: { (result, callback) in
                onTokenizeSuccessCalled = true
            },
            theme: PrimerTheme(),
            uxMode: .CHECKOUT,
            applePayEnabled: false,
            customerId: "cid",
            merchantIdentifier: "mid",
            countryCode: .FR
        )
        
        let paymentMethodConfigService = MockPaymentMethodConfigService()
        let clientTokenService = MockClientTokenService()
        let vaultPaymentMethodViewModel = MockVaultPaymentMethodViewModel()
        let applePayViewModel = MockApplePayViewModel()
        let vaultService = MockVaultService(paymentMethodsIsEmpty: true)
        
        let viewModel = VaultCheckoutViewModel(
            with: clientTokenService,
            and: vaultPaymentMethodViewModel,
            and: applePayViewModel,
            and: vaultService,
            and: settings
        )
        
        viewModel.authorizePayment({ error in })
        
        XCTAssertEqual(onTokenizeSuccessCalled, false)
    }
    
    func test_authorizePayment_does_not_call_onTokenizeSuccess_when_selected_method_id_no_match() throws {
        var onTokenizeSuccessCalled = false
        
        let settings = PrimerSettings(
            amount: 200,
            currency: .EUR,
            clientTokenRequestCallback: { completion in },
            onTokenizeSuccess: { (result, callback) in
                onTokenizeSuccessCalled = true
            },
            theme: PrimerTheme(),
            uxMode: .CHECKOUT,
            applePayEnabled: false,
            customerId: "cid",
            merchantIdentifier: "mid",
            countryCode: .FR
        )
        
        let paymentMethodConfigService = MockPaymentMethodConfigService()
        let clientTokenService = MockClientTokenService()
        let vaultPaymentMethodViewModel = MockVaultPaymentMethodViewModel()
        let applePayViewModel = MockApplePayViewModel()
        let vaultService = MockVaultService(selectedPaymentMethod: "noMatchId")
        
        let viewModel = VaultCheckoutViewModel(
            with: clientTokenService,
            and: vaultPaymentMethodViewModel,
            and: applePayViewModel,
            and: vaultService,
            and: settings
        )
        
        viewModel.authorizePayment({ error in })
        
        XCTAssertEqual(onTokenizeSuccessCalled, false)
    }
    
    
    
}










//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
