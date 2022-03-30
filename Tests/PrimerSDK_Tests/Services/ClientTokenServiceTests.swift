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
                if case PrimerError.invalidClientToken = err {
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

extension ClientTokenServiceTests {
    
    // MARK: Internal Validation
    
    // make the internal validation 40:95
    // if passes, then API call (both callback and promise functions)
    // if passes, store it
    
    private static func validateManuallyOrReturnPreviousToken(_ tokenToValidate: String) throws -> String {
        
        guard var currentDecodedToken = tokenToValidate.jwtTokenPayload,
              let expDate = currentDecodedToken.expDate,
              expDate > Date() else {
            let error = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: error)
            throw error
        }
                        
        let previousDecodedToken = ClientTokenService.decodedClientToken
        
        currentDecodedToken.configurationUrl = currentDecodedToken.configurationUrl?.replacingOccurrences(of: "10.0.2.2:8080", with: "localhost:8080")
        currentDecodedToken.coreUrl = currentDecodedToken.coreUrl?.replacingOccurrences(of: "10.0.2.2:8080", with: "localhost:8080")
        currentDecodedToken.pciUrl = currentDecodedToken.pciUrl?.replacingOccurrences(of: "10.0.2.2:8080", with: "localhost:8080")
        
        if currentDecodedToken.env == nil {
            currentDecodedToken.env = previousDecodedToken?.env
        }
        
        if currentDecodedToken.analyticsUrl == nil {
            currentDecodedToken.analyticsUrl = previousDecodedToken?.analyticsUrl
        }
        
        if currentDecodedToken.configurationUrl == nil {
            currentDecodedToken.configurationUrl = previousDecodedToken?.configurationUrl
        }
        
        if currentDecodedToken.coreUrl == nil {
            currentDecodedToken.coreUrl = previousDecodedToken?.coreUrl
        }
        
        if currentDecodedToken.pciUrl == nil {
            currentDecodedToken.pciUrl = previousDecodedToken?.pciUrl
        }
        
        var segments: [String] = tokenToValidate.split(separator: ".").compactMap({ String($0) })
        
        var tmpSecondSegment: String?
        if let data = try? JSONEncoder().encode(currentDecodedToken),
           let dataStr = String(data: data.base64EncodedData(), encoding: .utf8) {
            tmpSecondSegment = dataStr
        }
        
        if segments.count > 1, let tmpSecondSegment = tmpSecondSegment {
            segments[1] = tmpSecondSegment
        } else if segments.count == 1, let tmpSecondSegment = tmpSecondSegment {
            segments.append(tmpSecondSegment)
        }
        
        return segments.joined(separator: ".").base64RFC4648Format
        
    }
}


extension ClientTokenServiceTests {
    
    static func storeClientToken(_ clientToken: String, on state: AppState, completion: @escaping (Error?) -> Void) {
                
        // 1. Validate the token manually or return the previous one from current App State
        do {
            state.clientToken = try validateManuallyOrReturnPreviousToken(clientToken)
        } catch {
            completion(error)
            return
        }
        
        // 2. Validate the token from the dedicated API
        let clientTokenRequest = ClientTokenValidationRequest(clientToken: clientToken)
        let client = MockPrimerAPIClient()
        let validTokenResponse = SuccessResponse(success: true)
        let validTokenResponseData = try? JSONEncoder().encode(validTokenResponse)
        client.response = validTokenResponseData
        client.validateClientToken(request: clientTokenRequest) { result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(_):
                // 3. Assign the new token to the App State
                state.clientToken = clientToken
                completion(nil)
            }
        }
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
