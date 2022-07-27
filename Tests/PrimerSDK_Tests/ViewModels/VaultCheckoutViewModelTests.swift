//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class VaultCheckoutViewModelTests: XCTestCase {

    func test_loadConfig_calls_clientTokenService_if_client_token_nil() throws {
        
        let clientTokenService = MockClientTokenService()
        let state = MockAppState(decodedClientToken: nil)
        DependencyContainer.register(clientTokenService as ClientTokenServiceProtocol)
        DependencyContainer.register(state as AppStateProtocol)

        let viewModel = MockVaultCheckoutViewModel()

        viewModel.loadConfig({ _ in })

        XCTAssertEqual(clientTokenService.loadCheckoutConfigCalled, true)
    }
}

#endif
