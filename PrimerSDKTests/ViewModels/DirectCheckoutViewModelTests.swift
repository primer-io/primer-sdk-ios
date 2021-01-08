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
        
        let applePayViewModel = MockApplePayViewModel()
        let oAuthViewModel = MockOAuthViewModel()
        let cardFormViewModel = MockCardFormViewModel()
        let paymentMethodConfigService = MockPaymentMethodConfigService()
        let clientTokenService = MockClientTokenService()
        
        let viewModel = DirectCheckoutViewModel(
            with: mockSettings,
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
