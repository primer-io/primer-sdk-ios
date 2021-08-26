//
//  ClientTokenService.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import Primer3DS_SDK

class MockClientTokenService: ClientTokenServiceProtocol {
    let tokenIsNil: Bool

    init (tokenIsNil: Bool = false) {
        self.tokenIsNil = tokenIsNil
    }

    var decodedClientToken: DecodedClientToken? {
        if tokenIsNil { return nil }
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

    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) {
        loadCheckoutConfigCalled = true
    }
}

#endif
