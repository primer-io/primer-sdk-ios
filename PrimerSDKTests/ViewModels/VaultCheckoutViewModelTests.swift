//
//  PrimerSDKTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 07/12/2020.
//

import XCTest
@testable import PrimerSDK

class VaultCheckoutViewModelTests: XCTestCase {

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func test_loadConfig_calls_clientTokenService_if_client_token_nil() throws {
        let clientTokenService = MockClientTokenService()
        let serviceLocator = MockServiceLocator(clientTokenService: clientTokenService)
        let state = MockAppState(decodedClientToken: nil)
        let context = MockCheckoutContext(state: state, serviceLocator: serviceLocator)
        
        let viewModel = VaultCheckoutViewModel(context: context)
        
        viewModel.loadConfig({ error in })
        
        XCTAssertEqual(clientTokenService.loadCheckoutConfigCalled, true)
    }
}
