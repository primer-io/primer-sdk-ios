#if canImport(UIKit)

import Foundation

struct GetVaultedPaymentMethodsResponse: Decodable {
    var data: [PaymentMethodToken]
}

/**
 Each **PaymentMethodToken** represents a payment method added on Primer and carries the necessary information
 for identification (e.g. type), as well as further information to be used if needed.
 
 - Author:
 Primer
 - Version:
 1.2.2
 */

public class PaymentMethodToken: NSObject, Codable {
    public var token: String?
    public var analyticsId: String?
    public var tokenType: String?
    public var paymentInstrumentType: PaymentInstrumentType
    public var paymentInstrumentData: PaymentInstrumentData?
    public var vaultData: VaultData?
    public var threeDSecureAuthentication: ThreeDS.AuthenticationDetails?

    public override var description: String {
        switch self.paymentInstrumentType {
        case .paymentCard:
            let last4 = self.paymentInstrumentData?.last4Digits ?? "••••"
            return "•••• •••• •••• \(last4)"
        case .payPalOrder:
            return "PayPal"
        case .payPalBillingAgreement:
            return "PayPal"
        case .goCardlessMandate:
            return "Direct Debit"
        case .klarnaCustomerToken:
            return paymentInstrumentData?.sessionData?.billingAddress?.email ?? "Klarna Customer Token"
        case .klarna:
            return paymentInstrumentData?.sessionData?.billingAddress?.email ?? "Klarna"
        default:
            return "UNKNOWN"
        }
    }

    public var icon: ImageName {
        switch self.paymentInstrumentType {
        case .paymentCard:
            guard let network = self.paymentInstrumentData?.network else { return .genericCard }
            switch network {
            case "Visa": return .visa
            case "Mastercard": return .masterCard
            default: return .genericCard
            }
        case .payPalOrder: return .paypal2
        case .payPalBillingAgreement: return .paypal2
        case .goCardlessMandate: return .bank
        case .klarnaCustomerToken: return .klarna
        default: return .creditCard
        }
    }
    
//    public convenience init(token: String, paymentInstrumentType: PaymentInstrumentType, vaultData: VaultData) {
//        self.init(from: <#Decoder#>)
//        self.token = token
//        self.paymentInstrumentType = paymentInstrumentType
//        self.vaultData = vaultData
//    }
}

internal extension PaymentMethodToken {
    var cardButtonViewModel: CardButtonViewModel? {
        switch self.paymentInstrumentType {
        case .paymentCard:
            guard let ntwrk = self.paymentInstrumentData?.network else { return nil }
            guard let cardholder = self.paymentInstrumentData?.cardholderName else { return nil }
            guard let last4 = self.paymentInstrumentData?.last4Digits else { return nil }
            guard let expMonth = self.paymentInstrumentData?.expirationMonth else { return nil }
            guard let expYear = self.paymentInstrumentData?.expirationYear else { return nil }
            return CardButtonViewModel(
                network: ntwrk,
                cardholder: cardholder,
                last4: "•••• \(last4)",
                expiry: NSLocalizedString("primer-saved-card",
                                          tableName: nil,
                                          bundle: Bundle.primerResources,
                                          value: "Expires",
                                          comment: "Expires - Saved card")
                    + " \(expMonth) / \(expYear.suffix(2))",
                imageName: self.icon,
                paymentMethodType: self.paymentInstrumentType
            )
        case .payPalBillingAgreement:
            guard let cardholder = self.paymentInstrumentData?.externalPayerInfo?.email else { return nil }
            return CardButtonViewModel(network: "PayPal", cardholder: cardholder, last4: "", expiry: "", imageName: self.icon, paymentMethodType: self.paymentInstrumentType)
        case .goCardlessMandate:
            return CardButtonViewModel(network: "Bank account", cardholder: "", last4: "", expiry: "", imageName: self.icon, paymentMethodType: self.paymentInstrumentType)
        case .klarnaCustomerToken:
            return CardButtonViewModel(
                network: paymentInstrumentData?.sessionData?.billingAddress?.email ?? "Klarna Customer Token",
                cardholder: "",
                last4: "",
                expiry: "",
                imageName: self.icon,
                paymentMethodType: self.paymentInstrumentType
            )
        default:
            return nil
        }
    }
}

struct CardButtonViewModel {
    let network, cardholder, last4, expiry: String
    let imageName: ImageName
    let paymentMethodType: PaymentInstrumentType
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

#endif
