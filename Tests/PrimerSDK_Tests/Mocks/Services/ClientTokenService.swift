//
//  ClientTokenService.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockClientTokenService: ClientTokenServiceProtocol {
    static var clientToken: String?
    
    static func resetClientToken() {
        
    }
    
    
    let tokenIsNil: Bool
    var throwError: Bool

    init (tokenIsNil: Bool = false, throwError: Bool = false) {
        self.tokenIsNil = tokenIsNil
        self.throwError = throwError
    }

    static var decodedClientToken: DecodedClientToken? {
        return DecodedClientToken(
            accessToken: "bla",
            configurationUrl: "bla",
            paymentFlow: "bla",
            threeDSecureInitUrl: "bla",
            threeDSecureToken: "bla",
            coreUrl: "bla",
            pciUrl: "bla",
            env: "bla"
        )
    }

    var loadCheckoutConfigCalled = false
    
    static func storeClientToken(_ clientToken: String) throws {
        
    }
    
    func fetchClientToken(_ completion: @escaping (Error?) -> Void) {
        loadCheckoutConfigCalled = true
        if (throwError) { return completion(PrimerError.generic) }
        return completion(nil)
    }
}

#endif
