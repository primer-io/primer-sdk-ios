//
//  PrimerSDKTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 07/12/2020.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class VaultCheckoutViewModelTests: XCTestCase {

    func test_loadConfig_calls_clientTokenService_if_client_token_nil() throws {
        let clientTokenService = MockClientTokenService()
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        XCTAssertEqual(clientTokenService.loadCheckoutConfigCalled, true)
    }
}

#endif
