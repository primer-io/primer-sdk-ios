//
//  ApayaLoadWebViewModelTests.swift
//  PrimerSDK_Tests
//
//  Created by Carl Eriksson on 04/08/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class ApayaLoadWebViewModelTests: XCTestCase {
    
    override func setUp() {
        MockLocator.registerDependencies()
    }
    
    // MARK: generateWebViewUrl()
    func test_generateWebViewUrl_calls_apayaService() throws {
        let expectation = XCTestExpectation(description: "If configs are not nil apaya service should be called.")
        let apayaService = MockApayaService()
        DependencyContainer.register(apayaService as ApayaServiceProtocol)

        let viewModel = ApayaWebViewModel()

        viewModel.generateWebViewUrl { result in
            switch result {
            case .failure:
                XCTFail()
            case .success:
                XCTAssertTrue(apayaService.didCallCreatePaymentSession)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func test_if_config_nil_generateWebViewUrl_fetches_configs() throws {
        let state = MockAppState()
        let clientTokenService = MockClientTokenService()
        let paymentMethodConfigService = MockPaymentMethodConfigService()
        state.decodedClientToken = nil
        
        DependencyContainer.register(state as AppStateProtocol)
        DependencyContainer.register(clientTokenService as ClientTokenServiceProtocol)
        DependencyContainer.register(paymentMethodConfigService as PaymentMethodConfigServiceProtocol)

        let viewModel = ApayaWebViewModel()

        viewModel.generateWebViewUrl { _ in }
        XCTAssertTrue(clientTokenService.loadCheckoutConfigCalled)
        XCTAssertTrue(paymentMethodConfigService.fetchConfigCalled)
    }

    // MARK: tokenize()
    func test_tokenize_apaya_result_none_calls_router_with_error() throws {
//        let expectation = XCTestExpectation(description: "If apaya result is nil error should show.")
//        let state = MockAppState()
//        router.callback = {
//            switch router.route {
//            case .error:
//                XCTAssertTrue(router.showCalled)
//            default:
//                XCTFail()
//            }
//            expectation.fulfill()
//        }
//        DependencyContainer.register(state as AppStateProtocol)
//
//        let viewModel = ApayaLoadWebViewModel()
//        viewModel.tokenize()
//        wait(for: [expectation], timeout: 10.0)
    }
    
    func test_tokenize_apaya_result_error_calls_router_with_error() throws {
        let expectation = XCTestExpectation(description: "If apaya result is other exception error should show.")
        let router = MockRouter()
        let state = MockAppState()
        router.callback = {
            switch router.route {
            case .error:
                XCTAssertTrue(router.showCalled)
            default:
                XCTFail()
            }
            expectation.fulfill()
        }
        state.setApayaResult(.failure(ApayaException.failedApiCall))
        DependencyContainer.register(router as RouterDelegate)
        DependencyContainer.register(state as AppStateProtocol)
        
        let viewModel = ApayaLoadWebViewModel()
        viewModel.tokenize()
        wait(for: [expectation], timeout: 10.0)
    }
}

#endif
