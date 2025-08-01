//
//  TokenizationRequestPaymentInstrument.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

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

/**
 Enum exposing available payment methods

 *Values*

 `PAYMENT_CARD`: Used for card payments.

 `PAYPAL_ORDER`: Used for a one-off payment through PayPal. It cannot be stored in the vault.

 `PAYPAL_BILLING_AGREEMENT`: Used for a billing agreement through PayPal. It can be stored in the vault.

 `APPLE_PAY`: Used for a payment through Apple Pay.

 `GOOGLE_PAY`: Used for a payment through Google Pay.

 `GOCARDLESS_MANDATE`: Used for a Debit Direct payment.

 `KLARNA_PAYMENT_SESSION`:

 `KLARNA_CUSTOMER_TOKEN`: Used for vaulted Klarna payment methods.

 `KLARNA`:

 `unknown`: Unknown payment instrument..

 - Author:
 Primer
 - Version:
 1.2.2
 */

public enum PaymentInstrumentType: String, Codable {

    case paymentCard            = "PAYMENT_CARD"
    case offSession             = "OFF_SESSION_PAYMENT"
    case cardOffSession         = "CARD_OFF_SESSION_PAYMENT"
    case payPalOrder            = "PAYPAL_ORDER"
    case payPalBillingAgreement = "PAYPAL_BILLING_AGREEMENT"
    case applePay               = "APPLE_PAY"
    case googlePay              = "GOOGLE_PAY"
    case goCardlessMandate      = "GOCARDLESS_MANDATE"
    case klarna                 = "KLARNA_AUTHORIZATION_TOKEN"
    case klarnaPaymentSession   = "KLARNA_PAYMENT_SESSION"
    case klarnaCustomerToken    = "KLARNA_CUSTOMER_TOKEN"
    case hoolah                 = "HOOLAH"
    case stripeAch              = "AUTOMATED_CLEARING_HOUSE"
    case unknown                = "UNKNOWN"

    public init(from decoder: Decoder) throws {
        self = try PaymentInstrumentType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}

/**
 Contains extra information about the payment method.

 - Author:
 Primer
 - Version:
 1.2.2
 */

public struct BinData: Codable {
    public var network: String?
    public var issuerCountryCode: String?
    public var issuerName: String?
    public var issuerCurrencyCode: String?
    public var regionalRestriction: String?
    public var accountNumberType: String?
    public var accountFundingType: String?
    public var prepaidReloadableIndicator: String?
    public var productUsageType: String?
    public var productCode: String?
    public var productName: String?
}
