//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockClientTokenService: ClientTokenServiceProtocol {
    
    /// The client token from the DepedencyContainer
    static var decodedClientToken: DecodedClientToken? {
        guard let clientToken = MockAppState.current.clientToken else { return nil }
        guard let jwtTokenPayload = clientToken.jwtTokenPayload,
              let expDate = jwtTokenPayload.expDate
        else {
            return nil
        }
        
        if expDate < Date() {
            return nil
        }
        
        return jwtTokenPayload
    }
    
    static func storeClientToken(_ clientToken: String) -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
    
    static func storeClientToken(_ clientToken: String, completion: @escaping (Error?) -> Void) {
        completion(nil)
        return
    }
    
    func fetchClientToken() -> Promise<Void> {
        return Promise { seal in
            fetchClientToken { error in
                guard error == nil else {
                    seal.reject(error!)
                    return
                }
                seal.fulfill()
            }
        }
    }
    
    func fetchClientTokenIfNeeded() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
    
    
    let tokenIsNil: Bool
    var throwError: Bool

    init (tokenIsNil: Bool = false, throwError: Bool = false) {
        self.tokenIsNil = tokenIsNil
        self.throwError = throwError
    }

    var decodedClientToken: DecodedClientToken? {
        if tokenIsNil { return nil }
        return DecodedClientToken(accessToken: "bla", expDate: Date(timeIntervalSince1970: 2000000000), configurationUrl: "https://primer.io", paymentFlow: "bla", threeDSecureInitUrl: "https://primer.io", threeDSecureToken: "bla", coreUrl: "https://primer.io", pciUrl: "https://primer.io", env: "bla", intent: "bla", statusUrl: "https://primer.io", redirectUrl: "https://primer.io", qrCode: nil, accountNumber: nil)
    }

    var loadCheckoutConfigCalled = false
    
    func fetchClientToken(_ completion: @escaping (Error?) -> Void) {
        loadCheckoutConfigCalled = true
        if (throwError) { return completion(PrimerError.generic(message: "An error occured", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)) }
        return completion(nil)
    }
}

#endif
