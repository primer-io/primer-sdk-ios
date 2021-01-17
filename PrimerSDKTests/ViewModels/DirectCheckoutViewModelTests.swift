//
//  DirectCheckoutViewModelTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 03/01/2021.
//

import XCTest
@testable import PrimerSDK

class DirectCheckoutViewModelTests: XCTestCase {
    
    func test_loadCheckoutConfig_calls_clientTokenService_if_client_token_nil() throws {
        let clientTokenService = MockClientTokenService()
        let serviceLocator = MockServiceLocator(clientTokenService: clientTokenService)
        let state = MockAppState(decodedClientToken: nil)
        let context = MockCheckoutContext(state: state, serviceLocator: serviceLocator)
        
        let viewModel = DirectCheckoutViewModel(context: context)
        
        viewModel.loadCheckoutConfig({ error in })
        
        XCTAssertEqual(clientTokenService.loadCheckoutConfigCalled, true)
    }
    
}
