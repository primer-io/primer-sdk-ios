//
//  ClientTokenService.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockClientTokenService: ClientTokenServiceProtocol {
    
    let tokenIsNil: Bool
    var throwError: Bool

    init (clientToken: String? = nil, throwError: Bool = false) {
        self.tokenIsNil = (clientToken == nil)
        self.throwError = throwError
        
        if let clientToken = clientToken {
            try? ClientTokenService.storeClientToken(clientToken)
        }
    }

    static var decodedClientToken: DecodedClientToken? {
        return ClientTokenService.decodedClientToken
    }

    var loadCheckoutConfigCalled = false
    
    static func storeClientToken(_ clientToken: String) throws {
        try ClientTokenService.storeClientToken(clientToken)
    }
    
    func fetchClientToken(_ completion: @escaping (Error?) -> Void) {
        loadCheckoutConfigCalled = true
        if (throwError) { return completion(PrimerError.generic) }
        return completion(nil)
    }
    
    static func resetClientToken() {
        
    }
    
}

#endif
