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
    
    func test_generateWebViewUrl_calls_apaya_service() throws {
        let expectation = XCTestExpectation(description: "Generate Apaya URL | Calls Apaya Service.")
        let apayaService = MockApayaService()
        DependencyContainer.register(apayaService as ApayaServiceProtocol)

        let viewModel = ApayaLoadWebViewModel()

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
    func test_generateWebViewUrl_without_client_token_load_config() throws {
        let expectation = XCTestExpectation(description: "Generate Apaya URL Without Token | Calls Token Service.")
        let state = MockAppState()
        state.decodedClientToken = nil
        let clientTokenService = MockClientTokenService(tokenIsNil: false, throwError: true)
        DependencyContainer.register(state as AppStateProtocol)
        DependencyContainer.register(clientTokenService as ClientTokenServiceProtocol)

        let viewModel = ApayaLoadWebViewModel()

        viewModel.generateWebViewUrl { result in
            switch result {
            case .failure:
                XCTAssertTrue(clientTokenService.loadCheckoutConfigCalled)
                expectation.fulfill()
            case .success:
                XCTFail()
            }
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: tokenize()
    func test_tokenize_apaya_result_none_calls_router_with_error() throws {
        let expectation = XCTestExpectation(description: "tokenize | Route shown.")
        let router = MockRouter()
        let state = MockAppState()
        router.callback = {
            switch router.route {
            case .error:
                XCTAssertTrue(router.showCalled)
                expectation.fulfill()
            default:
                XCTFail()
            }
        }
        DependencyContainer.register(router as RouterDelegate)
        DependencyContainer.register(state as AppStateProtocol)
        
        let viewModel = ApayaLoadWebViewModel()
        viewModel.tokenize()
        wait(for: [expectation], timeout: 10.0)
    }
    func test_tokenize_apaya_result_error_cancelled_calls_router_pop() throws {
        let expectation = XCTestExpectation(description: "tokenize | Route pop.")
        let router = MockRouter()
        let state = MockAppState()
        router.callback = {
            XCTAssertTrue(router.popCalled)
            XCTAssertFalse(router.showCalled)
            XCTAssertNil(router.route)
            expectation.fulfill()
        }
        state.setApayaResult(.failure(.webViewFlowCancelled))
        DependencyContainer.register(router as RouterDelegate)
        DependencyContainer.register(state as AppStateProtocol)
        
        let viewModel = ApayaLoadWebViewModel()
        viewModel.tokenize()
        wait(for: [expectation], timeout: 10.0)
    }
    func test_tokenize_apaya_result_error_calls_router_with_error() throws {
        let expectation = XCTestExpectation(description: "tokenize | Route shown.")
        let router = MockRouter()
        let state = MockAppState()
        router.callback = {
            switch router.route {
            case .error:
                XCTAssertTrue(router.showCalled)
                expectation.fulfill()
            default:
                XCTFail()
            }
        }
        state.setApayaResult(.failure(.failedApiCall))
        DependencyContainer.register(router as RouterDelegate)
        DependencyContainer.register(state as AppStateProtocol)
        
        let viewModel = ApayaLoadWebViewModel()
        viewModel.tokenize()
        wait(for: [expectation], timeout: 10.0)
    }
}

#endif
