#if canImport(UIKit)

import Foundation

struct GetVaultedPaymentMethodsResponse: Decodable {
    var data: [PaymentMethod]
}

struct CardButtonViewModel {
    let network, cardholder, last4, expiry: String
    let imageName: ImageName
    let paymentMethodType: PaymentMethod.PaymentType
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

public enum PaymentInstrumentType: String {
    case card = "PAYMENT_CARD"
    case payPalOrder = "PAYPAL_ORDER"
    case payPalBillingAgreement = "PAYPAL_BILLING_AGREEMENT"
    case applePay = "APPLE_PAY"
    case googlePay = "GOOGLE_PAY"
    case goCardless = "GOCARDLESS_MANDATE"
    case klarna = "KLARNA_AUTHORIZATION_TOKEN"
    case klarnaPaymentSession = "KLARNA_PAYMENT_SESSION"
    case klarnaCustomerToken = "KLARNA_CUSTOMER_TOKEN"
    case apayaToken = "APAYA"
    case unknown = "UNKNOWN"
}

extension PaymentInstrumentType: Codable {
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

public protocol PaymentMethodDataProtocol: Codable {}

public typealias PaymentMethod = PaymentMethodToken

public class PaymentMethodToken: NSObject, Codable {
    
    public var token: String?
    public var analyticsId: String?
    public var tokenType: String?
    public var paymentInstrumentType: PaymentMethod.PaymentType
    public var paymentInstrumentData: PaymentMethodDataProtocol?
    public var vaultData: VaultData?
    public var threeDSecureAuthentication: ThreeDSecureAuthentication?
    public var title: String {
        if let paymentInstrumentData = paymentInstrumentData as? PaymentMethod.Data.Card {
            return "•••• •••• •••• \(paymentInstrumentData.last4Digits)"
        } else if let paymentInstrumentData = paymentInstrumentData as? PaymentMethod.Data.KlarnaCustomerToken {
            return paymentInstrumentData.sessionData.billingAddress?.email ?? "Klarna Customer Token"
        } else if let paymentInstrumentData = paymentInstrumentData as? PaymentMethod.Data.KlarnaAuthorizationToken {
            return paymentInstrumentData.sessionData.billingAddress?.email ?? "Klarna Customer Token"
        } else if let paymentInstrumentData = paymentInstrumentData as? PaymentMethod.Data.Apaya {
            return paymentInstrumentData.hashedIdentifier ?? "Pay by mobile"
        }
        
        switch paymentInstrumentType {
        case .goCardless:
            return "Direct Debit"
        case .payPalOrder,
             .payPalBillingAgreement:
            return "PayPal"
        default:
            return "Unknown"
        }
    }
    
    public var icon: ImageName {
        switch self.paymentInstrumentType {
        case .card:
            guard let cardData = self.paymentInstrumentData as? PaymentMethod.Data.Card else { return .genericCard }
            switch cardData.network {
            case "Visa":
                return .visa
            case "Mastercard":
                return .masterCard
            default:
                return .genericCard
            }
        case .payPalOrder:
            return .paypal2
        case .payPalBillingAgreement:
            return .paypal2
        case .goCardless:
            return .bank
        case .klarnaCustomerToken:
            return .klarna
        default:
            return .creditCard
        }
    }
    
    var cardButtonViewModel: CardButtonViewModel? {
        if let cardData = paymentInstrumentData as? PaymentMethod.Data.Card {
            guard let ntwrk = cardData.network else { return nil }
            guard let cardholder = cardData.cardholderName else { return nil }
            return CardButtonViewModel(
                network: ntwrk,
                cardholder: cardholder,
                last4: "•••• \(cardData.last4Digits)",
                expiry: NSLocalizedString("primer-saved-card",
                                          tableName: nil,
                                          bundle: Bundle.primerResources,
                                          value: "Expires",
                                          comment: "Expires - Saved card")
                    + " \(cardData.expirationMonth) / \(cardData.expirationYear.suffix(2))",
                imageName: self.icon,
                paymentMethodType: paymentInstrumentType
            )
            
        } else if let payPalBillingAgreementData = paymentInstrumentData as? PaymentMethod.Data.PayPalBillingAgreement {
            guard let cardholder = payPalBillingAgreementData.externalPayerInfo?.email else { return nil }
            return CardButtonViewModel(network: "PayPal", cardholder: cardholder, last4: "", expiry: "", imageName: self.icon, paymentMethodType: self.paymentInstrumentType)
        } else if let payPalBillingAgreementData = paymentInstrumentData as? PaymentMethod.Data.PayPalOrder {
            guard let cardholder = payPalBillingAgreementData.externalPayerInfo?.email else { return nil }
            return CardButtonViewModel(network: "PayPal", cardholder: cardholder, last4: "", expiry: "", imageName: self.icon, paymentMethodType: self.paymentInstrumentType)
        } else if let goCardlessData = paymentInstrumentData as? PaymentMethod.Data.GoCardless {
            return CardButtonViewModel(network: "Bank account", cardholder: "", last4: "", expiry: "", imageName: self.icon, paymentMethodType: self.paymentInstrumentType)
        } else if let klarnaCustomerTokenData = paymentInstrumentData as? PaymentMethod.Data.KlarnaCustomerToken {
            return CardButtonViewModel(
                network: klarnaCustomerTokenData.sessionData.billingAddress?.email ?? "Klarna Customer Token",
                cardholder: "",
                last4: "",
                expiry: "",
                imageName: self.icon,
                paymentMethodType: paymentInstrumentType
            )
        } else if let klarnaCustomerTokenData = paymentInstrumentData as? PaymentMethod.Data.KlarnaAuthorizationToken {
            return CardButtonViewModel(
                network: klarnaCustomerTokenData.sessionData.billingAddress?.email ?? "Klarna Customer Token",
                cardholder: "",
                last4: "",
                expiry: "",
                imageName: self.icon,
                paymentMethodType: paymentInstrumentType
            )
        } else if let apayaData = paymentInstrumentData as? PaymentMethod.Data.Apaya {
            return CardButtonViewModel(
                network: apayaData.hashedIdentifier ?? "Pay by mobile",
                cardholder: "",
                last4: "",
                expiry: "",
                imageName: self.icon,
                paymentMethodType: paymentInstrumentType
            )
        }
        
        return nil
    }
    
    enum CodingKeys: String, CodingKey {
        case token
        case analyticsId
        case tokenType
        case paymentInstrumentType
        case paymentInstrumentData
        case vaultData
        case threeDSecureAuthentication
    }
    
    init(
        token: String,
        analyticsId: String?,
        tokenType: String?,
        paymentInstrumentType: PaymentMethod.PaymentType,
        paymentInstrumentData: PaymentMethodDataProtocol?,
        vaultData: VaultData?,
        threeDSecureAuthentication: ThreeDSecureAuthentication?
    ) {
        self.token = token
        self.analyticsId = analyticsId
        self.tokenType = tokenType
        self.paymentInstrumentType = paymentInstrumentType
        self.paymentInstrumentData = paymentInstrumentData
        self.vaultData = vaultData
        self.threeDSecureAuthentication = threeDSecureAuthentication
        super.init()
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        token = try values.decode(String.self, forKey: .token)
        analyticsId = try? values.decode(String?.self, forKey: .analyticsId)
        tokenType = try? values.decode(String?.self, forKey: .tokenType)
        let paymentInstrumentTypeStr = try values.decode(String.self, forKey: .paymentInstrumentType)
        paymentInstrumentType = PaymentMethod.PaymentType(rawValue: paymentInstrumentTypeStr)!
        vaultData = try? values.decode(VaultData?.self, forKey: .vaultData)
        threeDSecureAuthentication = try? values.decode(ThreeDSecureAuthentication?.self, forKey: .threeDSecureAuthentication)
        
        if let data = try? values.decode(PaymentMethod.Data.Card?.self, forKey: .paymentInstrumentData) {
            paymentInstrumentData = data
        } else if let data = try? values.decode(PaymentMethod.Data.PayPalOrder?.self, forKey: .paymentInstrumentData) {
            paymentInstrumentData = data
        } else if let data = try? values.decode(PaymentMethod.Data.PayPalBillingAgreement?.self, forKey: .paymentInstrumentData) {
            paymentInstrumentData = data
        } else if let data = try? values.decode(PaymentMethod.Data.GoCardless?.self, forKey: .paymentInstrumentData) {
            paymentInstrumentData = data
        } else if let data = try? values.decode(PaymentMethod.Data.KlarnaAuthorizationToken?.self, forKey: .paymentInstrumentData) {
            paymentInstrumentData = data
        } else if let data = try? values.decode(PaymentMethod.Data.KlarnaCustomerToken?.self, forKey: .paymentInstrumentData) {
            paymentInstrumentData = data
        } else if let data = try? values.decode(PaymentMethod.Data.PayNLIdeal?.self, forKey: .paymentInstrumentData) {
            paymentInstrumentData = data
        } else if let data = try? values.decode(PaymentMethod.Data.Apaya?.self, forKey: .paymentInstrumentData) {
            paymentInstrumentData = data
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(token, forKey: .token)
        try container.encode(analyticsId, forKey: .analyticsId)
        try container.encode(tokenType, forKey: .tokenType)
        try container.encode(vaultData, forKey: .vaultData)
        try container.encode(threeDSecureAuthentication, forKey: .threeDSecureAuthentication)
                
        if let data = paymentInstrumentData as? PaymentMethod.Data.Card {
            try container.encode(data, forKey: .paymentInstrumentData)
        } else if let data = paymentInstrumentData as? PaymentMethod.Data.PayPalOrder {
            try container.encode(data, forKey: .paymentInstrumentData)
        } else if let data = paymentInstrumentData as? PaymentMethod.Data.PayPalBillingAgreement {
            try container.encode(data, forKey: .paymentInstrumentData)
        } else if let data = paymentInstrumentData as? PaymentMethod.Data.GoCardless {
            try container.encode(data, forKey: .paymentInstrumentData)
        } else if let data = paymentInstrumentData as? PaymentMethod.Data.KlarnaAuthorizationToken {
            try container.encode(data, forKey: .paymentInstrumentData)
        } else if let data = paymentInstrumentData as? PaymentMethod.Data.KlarnaCustomerToken {
            try container.encode(data, forKey: .paymentInstrumentData)
        } else if let data = paymentInstrumentData as? PaymentMethod.Data.PayNLIdeal {
            try container.encode(data, forKey: .paymentInstrumentData)
        } else if let data = paymentInstrumentData as? PaymentMethod.Data.Apaya {
            try container.encode(data, forKey: .paymentInstrumentData)
        }
    }
    
    public enum PaymentType: String, Codable {
        case card = "PAYMENT_CARD"
        case payPalOrder = "PAYPAL_ORDER"
        case payPalBillingAgreement = "PAYPAL_BILLING_AGREEMENT"
        case applePay = "APPLE_PAY"
        case googlePay = "GOOGLE_PAY"
        case goCardless = "GOCARDLESS_MANDATE"
        case klarna = "KLARNA_AUTHORIZATION_TOKEN"
        case klarnaPaymentSession = "KLARNA_PAYMENT_SESSION"
        case klarnaCustomerToken = "KLARNA_CUSTOMER_TOKEN"
        case apayaToken = "APAYA"
        case unknown = "UNKNOWN"
    }
    
    public struct Data: Codable {
        public struct Card: PaymentMethodDataProtocol {
            let last4Digits: String
            let expirationMonth: String
            let expirationYear: String
            let cardholderName: String?
            let network: String?
            let isNetworkTokenized: Bool
            let binData: BinData?
        }
        
        public struct PayPalOrder: PaymentMethodDataProtocol {
            public let paypalOrderId: String
            public let externalPayerInfo: ExternalPayerInfo?
            public let paypalStatus: String?
        }
        
        public struct PayPalBillingAgreement: PaymentMethodDataProtocol {
            public let paypalBillingAgreementId: String
            public let externalPayerInfo: ExternalPayerInfo?
            public let shippingAddress: ShippingAddress?
            public let paypalStatus: String?
        }
        
        public struct GoCardless: PaymentMethodDataProtocol {
            public let gocardlessMandateId: String
        }
        
        public struct KlarnaAuthorizationToken: PaymentMethodDataProtocol {
            public let klarnaAuthorizationToken: String
            public let sessionData: KlarnaSessionData
        }
        
        public struct KlarnaCustomerToken: PaymentMethodDataProtocol {
            public let klarnaCustomerToken: String
            public let sessionData: KlarnaSessionData
        }
        
        public struct PayNLIdeal: PaymentMethodDataProtocol {
            public let paymentMethodConfigId: String
        }
        
        public struct Apaya: PaymentMethodDataProtocol {
            let hashedIdentifier: String?
            let mnc: Int?
            let mcc: Int?
            let mx: String
            let currencyCode: Currency
            let productId: String?
        }
    }
}

/**
 Contains information of the payer (if available).
 
 *Values*
 
 `externalPayerId`: ID representing the payer.
 
 `email`: The payer's email.
 
 `firstName`: The payer's firstName.
 
 `lastName`: The payer's lastName.
 
 - Author:
 Primer
 - Version:
 1.2.2
 */

public struct ExternalPayerInfo: Codable {
    public var externalPayerId, email, firstName, lastName: String?
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
    public var customerId: String?
}

/**
 If available, it contains information on the 3DSecure authentication associated with this payment method token/instrument.
 
 - Author:
 Primer
 - Version:
 1.2.2
 */

public struct ThreeDSecureAuthentication: Codable {
    public var responseCode, reasonCode, reasonText, protocolVersion, challengeIssued: String?
}

#endif
