//
//  DecodedClientToken.swift
//  Debug App Tests
//
//  Created by Evangelos Pittas on 19/4/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

internal extension DecodedJWTToken {

    static func createMock(
        accessToken: String? = "access-token",
        env: String? = "sandbox",
        expDate: Date? = Date(timeIntervalSince1970: 2000000000),
        coreUrl: String? = "https://primer.io/core",
        configurationUrl: String? = "https://primer.io/config",
        pciUrl: String? = "https://primer.io/pci",
        paymentFlow: String? = "bla",
        intent: String? = "checkout",
        threeDSecureInitUrl: String? = "https://primer.io/3ds",
        threeDSecureToken: String? = "3ds-token",
        redirectUrl: String? = "https://primer.io/redirect",
        statusUrl: String? = "https://primer.io/status",
        qrCode: String? = "qr-code-base64-data",
        accountNumber: String? = "account-number",
        backendCallbackUrl: String? = "https://backend-callback-url.com",
        primerTransactionId: String? = "primer-transaction-id",
        iPay88PaymentMethodId: String? = "iPay88-payment-method-id",
        iPay88ActionType: String? = "iPay88-action-type",
        supportedCurrencyCode: String? = "GBP",
        supportedCountry: String? = "GB",
        nolPayTransactionNo: String? = "1714577102659239937"
    ) throws -> DecodedJWTToken {
        let decodedClientToken = DecodedJWTToken(
            accessToken: accessToken,
            expDate: expDate,
            configurationUrl: configurationUrl,
            paymentFlow: paymentFlow,
            threeDSecureInitUrl: threeDSecureInitUrl,
            threeDSecureToken: threeDSecureToken,
            supportedThreeDsProtocolVersions: nil,
            coreUrl: coreUrl,
            pciUrl: pciUrl,
            env: env,
            intent: intent,
            statusUrl: statusUrl,
            redirectUrl: redirectUrl,
            qrCode: qrCode,
            accountNumber: accountNumber,
            backendCallbackUrl: backendCallbackUrl,
            primerTransactionId: primerTransactionId,
            iPay88PaymentMethodId: iPay88PaymentMethodId,
            iPay88ActionType: iPay88ActionType,
            supportedCurrencyCode: supportedCurrencyCode,
            supportedCountry: supportedCountry,
            nolPayTransactionNo: nolPayTransactionNo)
        return decodedClientToken
    }

    func toString() throws -> String {
        let clientTokenSegment0 = "some-data".data(using: .utf8)!.base64EncodedString()
        let encodedClientToken = try JSONEncoder().encode(self)
        let clientTokenSegment1 = encodedClientToken.base64EncodedString()
        let clientTokenSegment2 = "some-data".data(using: .utf8)!.base64EncodedString()
        return "\(clientTokenSegment0).\(clientTokenSegment1).\(clientTokenSegment2)"
    }
}
