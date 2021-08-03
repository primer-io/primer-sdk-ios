//
//  OAuthViewControllerTests.swift
//  PrimerSDK_Example
//
//  Created by Carl Eriksson on 15/06/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

@available(iOS 11.0, *)
class OAuthViewControllerTests: XCTestCase {

    func test_paypal_load_exception_shows_error_screen() throws {
        let expectation = XCTestExpectation(description: "Load PayPal failed | Error message shown.")
        let viewModel = MockOAuthViewModel()
        viewModel.generateOAuthURLThrows = true
        let settings = mockSettings
        settings.isInitialLoadingHidden = true
        settings.hasDisabledSuccessScreen = false
        let router = MockRouter()
        
        router.callback = {
            XCTAssertTrue(viewModel.generateOAuthURLCalled)
            XCTAssertTrue(router.showCalled)
            expectation.fulfill()
        }

        MockLocator.registerDependencies()

        DependencyContainer.register(viewModel as OAuthViewModelProtocol)
        DependencyContainer.register(router as RouterDelegate)
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        let viewController = OAuthViewController(host: .paypal)

        viewController.viewDidLoad()
        
        wait(for: [expectation], timeout: 30.0)
    }
}

#endif
