//
//  JWTFactory.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 14/02/2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import Foundation

struct JWTHeaderSegment: Encodable {
    let typ: String
    let alg: String

    init(typ: String = "JWT", alg: String = "HS256") {
        self.typ = typ
        self.alg = alg
    }
}

struct JWTPayloadSegment: Encodable {
    let exp: UInt64
    let accessToken: String
    let analyticsUrl: String
    let intent: String
    let configurationUrl: String
    let coreUrl: String
    let pciUrl: String
    let env: String
    let threeDSecureInitUrl: String
    let threeDSecureToken: String
    let paymentFlow: String

    init(exp: UInt64 = 2625901334,
         accessToken: String = "00000000-0000-0000-0000-000000000000",
         analyticsUrl: String = "https://analytics.api.sandbox.core.primer.io/mixpanel",
         intent: String = "CHECKOUT",
         configurationUrl: String = "https://api.sandbox.primer.io/client-sdk/configuration",
         coreUrl: String = "https://api.sandbox.primer.io",
         pciUrl: String = "https://sdk.api.sandbox.primer.io",
         env: String = "SANDBOX",
         threeDSecureInitUrl: String = "https://songbirdstag.cardinalcommerce.com/cardinalcruise/v1/songbird.js",
         threeDSecureToken: String = "abc123",
         paymentFlow: String = "PREFER_VAULT") {
        self.exp = exp
        self.accessToken = accessToken
        self.analyticsUrl = analyticsUrl
        self.intent = intent
        self.configurationUrl = configurationUrl
        self.coreUrl = coreUrl
        self.pciUrl = pciUrl
        self.env = env
        self.threeDSecureInitUrl = threeDSecureInitUrl
        self.threeDSecureToken = threeDSecureToken
        self.paymentFlow = paymentFlow
    }
}

class JWTFactory {

    let encoder: JSONEncoder = JSONEncoder()

    func create(accessToken: String = "00000000-0000-0000-0000-000000000000",
                expiry: UInt64 = 2625901334) throws -> String {
        let header = String(data: try encoder.encode(JWTHeaderSegment()).base64EncodedData(), encoding: .utf8)!
        let payloadModel = JWTPayloadSegment(exp: expiry, accessToken: accessToken)
        let payload = String(data: try encoder.encode(payloadModel).base64EncodedData(), encoding: .utf8)!
        let signature = "5CZOemFCcuoQQEvlNqCb-aiKf7zwT7jXJxZZhHySM_o"
        return "\(header).\(payload).\(signature)"
    }
}
