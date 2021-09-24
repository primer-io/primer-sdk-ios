//
//  OAuthViewModel.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 07/01/2021.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class OAuthViewModelTests: XCTestCase {

    func test_generateOAuthURL_calls_paypalService_getAccessToken_if_client_token_nil() throws {
        let expectation = XCTestExpectation(description: "Create PayPal payment session")
        
        let paypalService = MockPayPalService()

        MockLocator.registerDependencies()

        DependencyContainer.register(paypalService as PayPalServiceProtocol)

        Primer.shared.showPaymentMethod(.payPal, withIntent: .vault, on: UIViewController())
        let viewModel = OAuthViewModel()
        viewModel.generateOAuthURL(.paypal, with: { _ in
            XCTAssertEqual(paypalService.startBillingAgreementSessionCalled, true)
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 5.0)
    }
}

#endif
