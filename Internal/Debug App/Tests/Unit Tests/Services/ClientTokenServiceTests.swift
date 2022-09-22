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
    
    // MARK: Internal Validation
    
    private static func validateInternally(_ tokenToValidate: String) throws -> String {
        
        guard var currentDecodedToken = tokenToValidate.jwtTokenPayload,
              let expDate = currentDecodedToken.expDate,
              expDate > Date() else {
            let error = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
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
    
    static func storeClientToken(_ clientToken: String, on state: AppStateProtocol, completion: @escaping (Error?) -> Void) {
                
        // 1. Validate the token internally
        do {
            state.clientToken = try validateInternally(clientToken)
        } catch {
            completion(error)
            return
        }
        
        // 2. Validate the token from the dedicated API
        let clientTokenRequest = Request.Body.ClientTokenValidation(clientToken: clientToken)
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
    func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {

    }
    
    
    func clientTokenCallback(_ completion: @escaping (String?, Error?) -> Void) {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            let state = MockAppState()
            DependencyContainer.register(state as AppStateProtocol)
            completion(state.clientToken, nil)
        }
    }
}

#endif
