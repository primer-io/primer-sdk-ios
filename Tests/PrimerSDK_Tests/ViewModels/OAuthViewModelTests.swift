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
        let paypalService = MockPayPalService()

        MockLocator.registerDependencies()

        DependencyContainer.register(paypalService as PayPalServiceProtocol)

        let viewModel = OAuthViewModel()

        viewModel.generateOAuthURL(.paypal, with: { _ in })

        XCTAssertEqual(paypalService.startOrderSessionCalled, true)
    }
}

#endif
