//
//  TokenizationPaymentInstrument.swift
//  PrimerSDK
//
//  Created by Evangelos on 29/8/22.
//



import Foundation

protocol TokenizationRequestBodyPaymentInstrument: Encodable {}

struct ApayaPaymentInstrument: TokenizationRequestBodyPaymentInstrument {
    var mx: String
    var mnc: String
    var mcc: String
    var hashedIdentifier: String
    var productId: String
    var currencyCode: String
}

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
    var klarnaCustomerToken: String
    var sessionData: Response.Body.Klarna.SessionData
}

class OffSessionPaymentInstrument: TokenizationRequestBodyPaymentInstrument {
    
    var paymentMethodConfigId: String
    var paymentMethodType: String
    var sessionInfo: OffSessionPaymentSessionInfo
    var type: PaymentInstrumentType = .offSession
    
    private enum CodingKeys : String, CodingKey {
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
        
        if let sessionInfo = sessionInfo as? BankSelectorSessionInfo {
            try container.encode(sessionInfo, forKey: .sessionInfo)
        } else if let sessionInfo = sessionInfo as? BlikSessionInfo {
            try container.encode(sessionInfo, forKey: .sessionInfo)
        } else if let sessionInfo = sessionInfo as? InputPhonenumberSessionInfo {
            try container.encode(sessionInfo, forKey: .sessionInfo)
        } else if let sessionInfo = sessionInfo as? PrimerTestPaymentMethodSessionInfo {
            try container.encode(sessionInfo, forKey: .sessionInfo)
        } else if let sessionInfo = sessionInfo as? WebRedirectSessionInfo {
            try container.encode(sessionInfo, forKey: .sessionInfo)
        } else if let sessionInfo = sessionInfo as? RetailOutletTokenizationSessionRequestParameters {
            try container.encode(sessionInfo, forKey: .sessionInfo)
        } else if let sessionInfo = sessionInfo as? IPay88SessionInfo {
            try container.encode(sessionInfo, forKey: .sessionInfo)
        } else if let sessionInfo = sessionInfo as? NolPaySessionInfo {
            try container.encode(sessionInfo, forKey: .sessionInfo)
        } else {
            let err = InternalError.invalidValue(
                key: "SessionInfo",
                value: self.sessionInfo,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
        
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
    case apayaToken             = "APAYA"
    case hoolah                 = "HOOLAH"
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


