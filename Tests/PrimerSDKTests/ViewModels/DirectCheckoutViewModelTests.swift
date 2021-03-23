//
//  DirectCheckoutViewModelTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 03/01/2021.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class DirectCheckoutViewModelTests: XCTestCase {
    
    override func tearDown() {
        DependencyContainer.clear()
    }
    
    func test_loadCheckoutConfig_calls_clientTokenService_if_client_token_nil() throws {
        let clientTokenService = MockClientTokenService()
        let state = MockAppState(decodedClientToken: nil)
        
        MockLocator.registerDependencies()
        DependencyContainer.register(state as AppStateProtocol)
        DependencyContainer.register(clientTokenService as ClientTokenServiceProtocol)
        
        let viewModel = DirectCheckoutViewModel()
        
        viewModel.loadCheckoutConfig({ error in })
        
        XCTAssertEqual(clientTokenService.loadCheckoutConfigCalled, true)
    }
    
}

#endif
