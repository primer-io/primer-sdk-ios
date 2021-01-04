//
//  DirectCheckoutViewModelTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 03/01/2021.
//

import XCTest
@testable import PrimerSDK

class DirectCheckoutViewModelTests: XCTestCase {
    
    func test_loadCheckoutConfig_calls_clientTokenService() throws {
        
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
        
        let applePayViewModel = MockApplePayViewModel()
        let oAuthViewModel = MockOAuthViewModel()
        let cardFormViewModel = MockCardFormViewModel()
        let paymentMethodConfigService = MockPaymentMethodConfigService()
        let clientTokenService = MockClientTokenService(with: settings, and: paymentMethodConfigService)
        
        let viewModel = DirectCheckoutViewModel(
            with: settings,
            and: applePayViewModel,
            and: oAuthViewModel,
            and: cardFormViewModel,
            and: clientTokenService,
            and: paymentMethodConfigService
        )
        
        viewModel.loadCheckoutConfig({ error in })
        
        XCTAssertEqual(clientTokenService.loadCheckoutConfigCalled, true)
    }
}
