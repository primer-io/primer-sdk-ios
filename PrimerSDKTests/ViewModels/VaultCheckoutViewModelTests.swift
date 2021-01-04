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
        
        let settings = PrimerSettings(
            uxMode: .CHECKOUT,
            amount: 200,
            currency: .EUR,
            merchantIdentifier: "mid",
            countryCode: .FR,
            applePayEnabled: false,
            customerId: "cid",
            clientTokenRequestCallback: { completionHandler in },
            onTokenizeSuccess: { (result, callback) in }
        )
        let paymentMethodConfigService = MockPaymentMethodConfigService()
        let clientTokenService = MockClientTokenService(with: settings, and: paymentMethodConfigService)
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
        
        viewModel.loadConfig({ error in })
        
        XCTAssertEqual(clientTokenService.loadCheckoutConfigCalled, true)
    }
    
    func test_VaultCheckoutViewModel_authorizePayment_calls_settings_onTokenizeSuccess() throws {
        
        var onTokenizeSuccessCalled = false
        
        let settings = PrimerSettings(
            uxMode: .CHECKOUT,
            amount: 200,
            currency: .EUR,
            merchantIdentifier: "mid",
            countryCode: .FR,
            applePayEnabled: false,
            customerId: "cid",
            clientTokenRequestCallback: { completionHandler in },
            onTokenizeSuccess: { (result, callback) in onTokenizeSuccessCalled = true }
        )
        let paymentMethodConfigService = MockPaymentMethodConfigService()
        let clientTokenService = MockClientTokenService(with: settings, and: paymentMethodConfigService)
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
}

//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
