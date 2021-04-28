//
//  ClientTokenServiceTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 03/01/2021.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class ClientTokenServiceTests: XCTestCase {

    func test_loadCheckoutConfig_calls_clientTokenRequestCallback() throws {
        let expectation = XCTestExpectation(description: "Load checkout config")

        let accessToken = "7651512a-d12e-46e1-b58c-d8c3afc8c8ee"
        let response = CreateClientTokenResponse(
            clientToken: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhY2Nlc3NUb2tlbiI6Ijc2NTE1MTJhLWQxMmUtNDZlMS1iNThjLWQ4YzNhZmM4YzhlZSIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJwYXltZW50RmxvdyI6IlBSRUZFUl9WQVVMVCIsInRocmVlRFNlY3VyZUluaXRVcmwiOiJodHRwczovL3NvbmdiaXJkc3RhZy5jYXJkaW5hbGNvbW1lcmNlLmNvbS9jYXJkaW5hbGNydWlzZS92MS9zb25nYmlyZC5qcyIsInRocmVlRFNlY3VyZVRva2VuIjoiZXlKMGVYQWlPaUpLVjFRaUxDSmhiR2NpT2lKSVV6STFOaUo5LmV5SnFkR2tpT2lJMFpEUTFPRFF5TkMwd01ESmpMVFJpTlRjdFlUYzNZeTA1Tm1abFptUTNOekl3WTJJaUxDSnBZWFFpT2pFMk1EY3hPRFkzTXpnc0ltbHpjeUk2SWpWbFlqVmlZV1ZqWlRabFl6Y3lObVZoTldaaVlUZGxOU0lzSWs5eVoxVnVhWFJKWkNJNklqVmxZalZpWVRReFpEUTRabUprTmpBNE9EaGlPR1UwTkNKOS4wRVk0alV6RFBUVUE1Y1VaZ3F1d0lvZDRvM2l1SzRYbmY4TUtXQnoxSHEwIiwiY29yZVVybCI6Imh0dHBzOi8vYXBpLnNhbmRib3gucHJpbWVyLmlvIiwicGNpVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIn0.s08j_MIxosYNTfUNtLnJELxeLqRVryPvFtdZfEjie08",
            expirationDate: "2020-12-06T16:45:38.963044"
        )

        var clientTokenRequestCallbackCalled = false

        let settings = MockPrimerSettings(clientTokenRequestCallback: { completion in
            clientTokenRequestCallbackCalled = true
            completion(.success(response))
            XCTAssertEqual(clientTokenRequestCallbackCalled, true)
            expectation.fulfill()
        })

        MockLocator.registerDependencies()
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        
        let service = ClientTokenService()

        service.loadCheckoutConfig({ _ in })

        XCTAssertEqual(state.decodedClientToken?.accessToken, accessToken)

        wait(for: [expectation], timeout: 10.0)
    }

}

#endif
