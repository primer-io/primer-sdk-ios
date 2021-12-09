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
    
    let clientToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE2MjA0NTI2MDksImFjY2Vzc1Rva2VuIjoiZGNjNGI1NjUtZmM2Mi00NDVmLWEzNzktYTdmMDdkYzkwOTM3IiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnNhbmRib3guY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJpbnRlbnQiOiJDSEVDS09VVCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwidGhyZWVEU2VjdXJlSW5pdFVybCI6Imh0dHBzOi8vc29uZ2JpcmRzdGFnLmNhcmRpbmFsY29tbWVyY2UuY29tL2NhcmRpbmFsY3J1aXNlL3YxL3NvbmdiaXJkLmpzIiwidGhyZWVEU2VjdXJlVG9rZW4iOiJleUowZVhBaU9pSktWMVFpTENKaGJHY2lPaUpJVXpJMU5pSjkuZXlKcWRHa2lPaUpoWlRSaVltRTRNUzFqTm1WakxUUTJZVGt0WVdRell5MWhNV0V3T1RJMk1UYzBPVEVpTENKcFlYUWlPakUyTWpBek5qWXlNRGtzSW1semN5STZJalZsWWpWaVlXVmpaVFpsWXpjeU5tVmhOV1ppWVRkbE5TSXNJazl5WjFWdWFYUkpaQ0k2SWpWbFlqVmlZVFF4WkRRNFptSmtOakE0T0RoaU9HVTBOQ0o5LmlIbGhjbWRMVE1sVURKMXREY0hFVkhjT01hZUstUUJTTGFXczJVVVJnOGsiLCJwYXltZW50RmxvdyI6IlBSRUZFUl9WQVVMVCJ9.7v55XlO8zpIjsKTtMDtowdT2nfyULuLNTaw-B1qEi2I"

    func test_loadCheckoutConfig_calls_clientTokenRequestCallback() throws {
        let expectation = XCTestExpectation(description: "Load checkout config")

        let accessToken = "dcc4b565-fc62-445f-a379-a7f07dc90937"
        

        Primer.shared.delegate = self

        MockLocator.registerDependencies()
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        
        let service = ClientTokenService()
        service.fetchClientToken { (err) in
            if let err = err {
                if case PrimerError.clientTokenExpired = err {
                    XCTAssert(true, err.localizedDescription)
                } else {
                    XCTAssert(false, err.localizedDescription)
                }
            } else {
                XCTAssertEqual(state.clientToken?.jwtTokenPayload?.accessToken, accessToken)
            }
            
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 30.0)
    }

}

extension ClientTokenServiceTests: PrimerDelegate {
    func clientTokenCallback(_ completion: @escaping (String?, Error?) -> Void) {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            completion(self.clientToken, nil)
        }
    }
}

#endif
