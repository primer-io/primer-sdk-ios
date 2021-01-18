//
//  OAuthViewModel.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 07/01/2021.
//

import XCTest
@testable import PrimerSDK

class OAuthViewModelTests: XCTestCase {
    
    func test_generateOAuthURL_calls_paypalService_getAccessToken_if_client_token_nil() throws {
        let paypalService = MockPayPalService()
        let serviceLocator = MockServiceLocator(paypalService: paypalService)
        let context = MockCheckoutContext(serviceLocator: serviceLocator)
        
        let viewModel: OAuthViewModel = OAuthViewModel(context: context)
        
        viewModel.generateOAuthURL(with: { result in })
        
        XCTAssertEqual(paypalService.startOrderSessionCalled, true)
    }
}

