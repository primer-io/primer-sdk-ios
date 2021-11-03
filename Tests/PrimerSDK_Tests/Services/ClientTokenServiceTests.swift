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
    
    var clientToken: String!
    
    func initializeSDK() {
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        Primer.shared.delegate = self
    }
    
    func test_load_client_token_callback() throws {
        let validToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjI2MjA0NTI2MDksImFjY2Vzc1Rva2VuIjoiZGNjNGI1NjUtZmM2Mi00NDVmLWEzNzktYTdmMDdkYzkwOTM3IiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnNhbmRib3guY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJpbnRlbnQiOiJDSEVDS09VVCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwidGhyZWVEU2VjdXJlSW5pdFVybCI6Imh0dHBzOi8vc29uZ2JpcmRzdGFnLmNhcmRpbmFsY29tbWVyY2UuY29tL2NhcmRpbmFsY3J1aXNlL3YxL3NvbmdiaXJkLmpzIiwidGhyZWVEU2VjdXJlVG9rZW4iOiJleUowZVhBaU9pSktWMVFpTENKaGJHY2lPaUpJVXpJMU5pSjkuZXlKcWRHa2lPaUpoWlRSaVltRTRNUzFqTm1WakxUUTJZVGt0WVdRell5MWhNV0V3T1RJMk1UYzBPVEVpTENKcFlYUWlPakUyTWpBek5qWXlNRGtzSW1semN5STZJalZsWWpWaVlXVmpaVFpsWXpjeU5tVmhOV1ppWVRkbE5TSXNJazl5WjFWdWFYUkpaQ0k2SWpWbFlqVmlZVFF4WkRRNFptSmtOakE0T0RoaU9HVTBOQ0o5LmlIbGhjbWRMVE1sVURKMXREY0hFVkhjT01hZUstUUJTTGFXczJVVVJnOGsiLCJwYXltZW50RmxvdyI6IlBSRUZFUl9WQVVMVCJ9.RMqc8MjYhltrlfNmXK3R0IZOaHQvIzhJdNL_nScy08Y"
        
        clientToken = validToken
        initializeSDK()
        ClientTokenService.resetClientToken()
        
        let expectation = XCTestExpectation(description: "Load client token")
        
        let clientTokenService: ClientTokenServiceProtocol = ClientTokenService()
        clientTokenService.fetchClientToken { err in
            XCTAssert(ClientTokenService.decodedClientToken?.accessToken == "dcc4b565-fc62-445f-a379-a7f07dc90937", "Access token should be dcc4b565-fc62-445f-a379-a7f07dc90937")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test_load_client_token_promise() throws {
        let validToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjI2MjA0NTI2MDksImFjY2Vzc1Rva2VuIjoiZGNjNGI1NjUtZmM2Mi00NDVmLWEzNzktYTdmMDdkYzkwOTM3IiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnNhbmRib3guY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJpbnRlbnQiOiJDSEVDS09VVCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwidGhyZWVEU2VjdXJlSW5pdFVybCI6Imh0dHBzOi8vc29uZ2JpcmRzdGFnLmNhcmRpbmFsY29tbWVyY2UuY29tL2NhcmRpbmFsY3J1aXNlL3YxL3NvbmdiaXJkLmpzIiwidGhyZWVEU2VjdXJlVG9rZW4iOiJleUowZVhBaU9pSktWMVFpTENKaGJHY2lPaUpJVXpJMU5pSjkuZXlKcWRHa2lPaUpoWlRSaVltRTRNUzFqTm1WakxUUTJZVGt0WVdRell5MWhNV0V3T1RJMk1UYzBPVEVpTENKcFlYUWlPakUyTWpBek5qWXlNRGtzSW1semN5STZJalZsWWpWaVlXVmpaVFpsWXpjeU5tVmhOV1ppWVRkbE5TSXNJazl5WjFWdWFYUkpaQ0k2SWpWbFlqVmlZVFF4WkRRNFptSmtOakE0T0RoaU9HVTBOQ0o5LmlIbGhjbWRMVE1sVURKMXREY0hFVkhjT01hZUstUUJTTGFXczJVVVJnOGsiLCJwYXltZW50RmxvdyI6IlBSRUZFUl9WQVVMVCJ9.RMqc8MjYhltrlfNmXK3R0IZOaHQvIzhJdNL_nScy08Y"
        
        clientToken = validToken
        initializeSDK()
        ClientTokenService.resetClientToken()
        
        let expectation = XCTestExpectation(description: "Load client token")
        
        let clientTokenService: ClientTokenServiceProtocol = ClientTokenService()
        firstly {
            clientTokenService.fetchClientTokenIfNeeded(enforce: true)
        }
        .done {
            XCTAssert(ClientTokenService.decodedClientToken?.accessToken == "dcc4b565-fc62-445f-a379-a7f07dc90937", "Access token should be dcc4b565-fc62-445f-a379-a7f07dc90937")
        }
        .ensure {
            expectation.fulfill()
        }
        .catch { err in
            
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test_not_storing_expired_client_token() {
        let expiredToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE2MjA0NTI2MDksImFjY2Vzc1Rva2VuIjoiZGNjNGI1NjUtZmM2Mi00NDVmLWEzNzktYTdmMDdkYzkwOTM3IiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnNhbmRib3guY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJpbnRlbnQiOiJDSEVDS09VVCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwidGhyZWVEU2VjdXJlSW5pdFVybCI6Imh0dHBzOi8vc29uZ2JpcmRzdGFnLmNhcmRpbmFsY29tbWVyY2UuY29tL2NhcmRpbmFsY3J1aXNlL3YxL3NvbmdiaXJkLmpzIiwidGhyZWVEU2VjdXJlVG9rZW4iOiJleUowZVhBaU9pSktWMVFpTENKaGJHY2lPaUpJVXpJMU5pSjkuZXlKcWRHa2lPaUpoWlRSaVltRTRNUzFqTm1WakxUUTJZVGt0WVdRell5MWhNV0V3T1RJMk1UYzBPVEVpTENKcFlYUWlPakUyTWpBek5qWXlNRGtzSW1semN5STZJalZsWWpWaVlXVmpaVFpsWXpjeU5tVmhOV1ppWVRkbE5TSXNJazl5WjFWdWFYUkpaQ0k2SWpWbFlqVmlZVFF4WkRRNFptSmtOakE0T0RoaU9HVTBOQ0o5LmlIbGhjbWRMVE1sVURKMXREY0hFVkhjT01hZUstUUJTTGFXczJVVVJnOGsiLCJwYXltZW50RmxvdyI6IlBSRUZFUl9WQVVMVCJ9.7v55XlO8zpIjsKTtMDtowdT2nfyULuLNTaw-B1qEi2I"
        
        clientToken = expiredToken
        initializeSDK()
        ClientTokenService.resetClientToken()
        
        let expectation = XCTestExpectation(description: "Expecting null token because it's expired.")
        
        let clientTokenService: ClientTokenServiceProtocol = ClientTokenService()
        clientTokenService.fetchClientToken { err in
            XCTAssert(ClientTokenService.clientToken == nil, "Client token should be null")
            XCTAssert(ClientTokenService.decodedClientToken == nil, "Decoded client token should be nil")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test_not_storing_invalid_client_token() {
        let invalidToken = "_"
        
        clientToken = invalidToken
        initializeSDK()
        ClientTokenService.resetClientToken()
        
        let expectation = XCTestExpectation(description: "Expecting null token because it's invalid.")
        
        let clientTokenService: ClientTokenServiceProtocol = ClientTokenService()
        clientTokenService.fetchClientToken { err in
            XCTAssert(ClientTokenService.clientToken == nil, "Client token should be null")
            XCTAssert(ClientTokenService.decodedClientToken == nil, "Decoded client token should be nil")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test_reseting_client_token() {
        let validToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjI2MjA0NTI2MDksImFjY2Vzc1Rva2VuIjoiZGNjNGI1NjUtZmM2Mi00NDVmLWEzNzktYTdmMDdkYzkwOTM3IiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnNhbmRib3guY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJpbnRlbnQiOiJDSEVDS09VVCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwidGhyZWVEU2VjdXJlSW5pdFVybCI6Imh0dHBzOi8vc29uZ2JpcmRzdGFnLmNhcmRpbmFsY29tbWVyY2UuY29tL2NhcmRpbmFsY3J1aXNlL3YxL3NvbmdiaXJkLmpzIiwidGhyZWVEU2VjdXJlVG9rZW4iOiJleUowZVhBaU9pSktWMVFpTENKaGJHY2lPaUpJVXpJMU5pSjkuZXlKcWRHa2lPaUpoWlRSaVltRTRNUzFqTm1WakxUUTJZVGt0WVdRell5MWhNV0V3T1RJMk1UYzBPVEVpTENKcFlYUWlPakUyTWpBek5qWXlNRGtzSW1semN5STZJalZsWWpWaVlXVmpaVFpsWXpjeU5tVmhOV1ppWVRkbE5TSXNJazl5WjFWdWFYUkpaQ0k2SWpWbFlqVmlZVFF4WkRRNFptSmtOakE0T0RoaU9HVTBOQ0o5LmlIbGhjbWRMVE1sVURKMXREY0hFVkhjT01hZUstUUJTTGFXczJVVVJnOGsiLCJwYXltZW50RmxvdyI6IlBSRUZFUl9WQVVMVCJ9.RMqc8MjYhltrlfNmXK3R0IZOaHQvIzhJdNL_nScy08Y"
        
        clientToken = validToken
        initializeSDK()
        ClientTokenService.resetClientToken()
        
        let expectation = XCTestExpectation(description: "Load client token")
        
        let clientTokenService: ClientTokenServiceProtocol = ClientTokenService()
        clientTokenService.fetchClientToken { err in
            ClientTokenService.resetClientToken()
            XCTAssert(ClientTokenService.clientToken == nil, "Client token should be reset")
            XCTAssert(ClientTokenService.decodedClientToken == nil, "Decoded client token should be nil")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
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
