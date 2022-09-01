//
//  TokenizationPaymentInstrument.swift
//  PrimerSDK
//
//  Created by Evangelos on 29/8/22.
//

#if canImport(UIKit)

import Foundation

protocol TokenizationPaymentInstrument: Encodable {}

struct ApayaPaymentInstrument: TokenizationPaymentInstrument {
    var mx: String
    var mnc: String
    var mcc: String
    var hashedIdentifier: String
    var productId: String
    var currencyCode: String
}

struct ApplePayPaymentInstrument: TokenizationPaymentInstrument {
    
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

struct CardPaymentInstrument: TokenizationPaymentInstrument {
    var number: String
    var cvv: String
    var expirationMonth: String
    var expirationYear: String
    var cardholderName: String?
}

struct KlarnaCustomerTokenPaymentInstrument: TokenizationPaymentInstrument {
    var klarnaCustomerToken: String?
    var sessionData: KlarnaSessionData?
}

struct KlarnaPaymentSessionPaymentInstrument: TokenizationPaymentInstrument {
    var klarnaAuthorizationToken: String
    var sessionData: KlarnaSessionData
}

class OffSessionPaymentInstrument: TokenizationPaymentInstrument {
    
    var paymentMethodConfigId: String
    var paymentMethodType: String
    var sessionInfo: OffSessionPaymentSessionInfo
    var type: String = "OFF_SESSION_PAYMENT"
    
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
        } else {
            let err = InternalError.invalidValue(key: "SessionInfo", value: self.sessionInfo, userInfo: nil, diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        try container.encode(type, forKey: .type)
    }
}

struct PayPalPaymentInstrument: TokenizationPaymentInstrument {
    var paypalOrderId: String?
    var paypalBillingAgreementId: String?
    var shippingAddress: ShippingAddress?
    var externalPayerInfo: ExternalPayerInfo?
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
    
    case paymentCard = "PAYMENT_CARD"
    case payPalOrder = "PAYPAL_ORDER"
    case payPalBillingAgreement = "PAYPAL_BILLING_AGREEMENT"
    case applePay = "APPLE_PAY"
    case googlePay = "GOOGLE_PAY"
    case goCardlessMandate = "GOCARDLESS_MANDATE"
    case klarna = "KLARNA_AUTHORIZATION_TOKEN"
    case klarnaPaymentSession = "KLARNA_PAYMENT_SESSION"
    case klarnaCustomerToken = "KLARNA_CUSTOMER_TOKEN"
    case apayaToken = "APAYA"
    case hoolah = "HOOLAH"
    case unknown = "UNKNOWN"

    public init(from decoder: Decoder) throws {
        self = try PaymentInstrumentType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}

/**
 This structure contains all the available information on the payment instrument. Each payment instrument contains its own data,
 therefore not all fields will have a value.
 
 - Author:
 Primer
 - Version:
 1.2.2
 */

public struct PaymentInstrumentData: Codable {
    public let paypalBillingAgreementId: String?
    public let first6Digits: String?
    public let last4Digits: String?
    public let expirationMonth: String?
    public let expirationYear: String?
    public let cardholderName: String?
    public let network: String?
    public let isNetworkTokenized: Bool?
    public let klarnaCustomerToken: String?
    public let sessionData: KlarnaSessionData?
    public let externalPayerInfo: ExternalPayerInfo?
    public let shippingAddress: ShippingAddress?
    public let binData: BinData?
    public let threeDSecureAuthentication: ThreeDS.AuthenticationDetails?
    public let gocardlessMandateId: String?
    public let authorizationToken: String?
    // APAYA
    public let hashedIdentifier: String?
    public let mnc: Int?
    public let mcc: Int?
    public let mx: String?
    public let currencyCode: Currency?
    public let productId: String?
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

public struct VaultData: Codable {
    public var customerId: String
}

#endif
