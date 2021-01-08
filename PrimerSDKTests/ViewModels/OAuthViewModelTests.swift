//
//  OAuthViewModel.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 07/01/2021.
//

import XCTest
@testable import PrimerSDK

class OAuthViewModelTests: XCTestCase {
    
    func test_generateOAuthURL_calls_paypalService_getAccessToken() throws {
        
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
        let paypalService = MockPayPalService()
        let tokenizationService = MockTokenizationService()
        let paymentMethodConfigService = MockPaymentMethodConfigService()
        
        let viewModel: OAuthViewModel = OAuthViewModel(
            with: settings,
            and: paypalService,
            and: tokenizationService,
            and: clientTokenService,
            and: paymentMethodConfigService
        )
        
        viewModel.generateOAuthURL(with: { result in })
        
        XCTAssertEqual(paypalService.getAccessTokenCalled, true)
        
    }
}

