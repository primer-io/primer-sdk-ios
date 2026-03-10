//
//  TokenizationRequestPaymentInstrument.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerNetworking

protocol TokenizationRequestBodyPaymentInstrument: Encodable {}

struct ApplePayPaymentInstrument: TokenizationRequestBodyPaymentInstrument {

    var paymentMethodConfigId: String
    var sourceConfig: ApplePayPaymentInstrument.SourceConfig
    var token: ApplePayPaymentInstrument.PaymentResponseToken

    struct SourceConfig: Codable {
        let source: String
        let merchantId: String
    }

    struct PaymentResponseToken: Codable {
        let paymentMethod: ApplePayPaymentResponsePaymentMethod
        let transactionIdentifier: String
        let paymentData: ApplePayPaymentResponseTokenPaymentData
    }
}

struct CardPaymentInstrument: TokenizationRequestBodyPaymentInstrument {
    var number: String
    var cvv: String
    var expirationMonth: String
    var expirationYear: String
    var cardholderName: String?
    var preferredNetwork: String?
}

struct CardOffSessionPaymentInstrument: TokenizationRequestBodyPaymentInstrument {
    var sessionInfo = CardOffSessionInfo()
    var type: PaymentInstrumentType = .cardOffSession
    var paymentMethodConfigId: String
    var paymentMethodType: String
    var number: String
    var expirationMonth: String
    var expirationYear: String
    var cardholderName: String
}

struct KlarnaCustomerTokenPaymentInstrument: TokenizationRequestBodyPaymentInstrument {
    var klarnaCustomerToken: String?
    var sessionData: Response.Body.Klarna.SessionData
}

struct KlarnaAuthorizationPaymentInstrument: TokenizationRequestBodyPaymentInstrument {
    var klarnaAuthorizationToken: String?
    var sessionData: Response.Body.Klarna.SessionData
}

struct ACHPaymentInstrument: TokenizationRequestBodyPaymentInstrument {
    var paymentMethodConfigId: String
    var paymentMethodType: String
    var authenticationProvider: String
    var type: String
    var sessionInfo: Request.Body.StripeAch.SessionData
}

final class OffSessionPaymentInstrument: TokenizationRequestBodyPaymentInstrument {

    var paymentMethodConfigId: String
    var paymentMethodType: String
    var sessionInfo: OffSessionPaymentSessionInfo
    var type: PaymentInstrumentType = .offSession

    private enum CodingKeys: String, CodingKey {
        case paymentMethodConfigId, paymentMethodType, sessionInfo, type
    }

    init(paymentMethodConfigId: String, paymentMethodType: String, sessionInfo: OffSessionPaymentSessionInfo) {
        self.paymentMethodConfigId = paymentMethodConfigId
        self.paymentMethodType = paymentMethodType
        self.sessionInfo = sessionInfo
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(paymentMethodConfigId, forKey: .paymentMethodConfigId)
        try container.encode(paymentMethodType, forKey: .paymentMethodType)
        try container.encode(sessionInfo, forKey: .sessionInfo)
        try container.encode(type, forKey: .type)
    }
}

struct PayPalPaymentInstrument: TokenizationRequestBodyPaymentInstrument {
    var paypalOrderId: String?
    var paypalBillingAgreementId: String?
    var shippingAddress: Response.Body.Tokenization.PayPal.ShippingAddress?
    var externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo?
}
