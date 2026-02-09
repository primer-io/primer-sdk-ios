//
//  ClientToken.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerNetworking

extension Request.Body {

    struct ClientTokenValidation: Encodable {
        let clientToken: String
    }
}

extension DecodedJWTToken {
    
    var isValid: Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }

    func validate() throws {
        if accessToken == nil {
            throw handled(primerError: .invalidClientToken(reason: "Access token is nil"))
        }

        guard let expDate = expDate else {
            throw handled(
                primerError: .invalidValue(key: "expDate", reason: "Expiry date missing")
            )
        }

        if expDate < Date() {
            throw handled(
                primerError: .invalidValue(key: "expDate", reason: "Expiry datetime has passed.")
            )
        }
    }
}
