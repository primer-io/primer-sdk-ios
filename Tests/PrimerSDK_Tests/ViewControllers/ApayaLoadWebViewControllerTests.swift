//
//  ApayaLoadWebViewController.swift
//  PrimerSDK_Tests
//
//  Created by Carl Eriksson on 04/08/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class ApayaLoadWebViewControllerTests: XCTestCase {
    func test_generateUrl_error_calls_router_show() throws {
        let expectation = XCTestExpectation(description: "Generate Apaya URL Error | Route shown.")
        let viewModel = MockApayaLoadWebViewModel(url: "https://primer.io", shouldThrow: true)
        let settings = mockSettings
        settings.isInitialLoadingHidden = true
        settings.hasDisabledSuccessScreen = false
        let router = MockRouter()
        router.callback = {
            XCTAssertTrue(viewModel.didCallGenerateWebViewUrl)
            XCTAssertTrue(router.showCalled)
            expectation.fulfill()
        }
        MockLocator.registerDependencies()
        DependencyContainer.register(viewModel as ApayaLoadWebViewModelProtocol)
        DependencyContainer.register(router as RouterDelegate)
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        let viewController = ApayaLoadWebViewController()
        viewController.generateUrl()
        
        wait(for: [expectation], timeout: 10.0)
    }
}

#endif
