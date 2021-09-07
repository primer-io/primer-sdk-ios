#if canImport(UIKit)

import UIKit

public enum PaymentMethodType {
    case card
    case paypal
    case applepay
}

struct PaymentMethod {
    let type: PaymentMethodType
    var details: PaymentMethod.Details
    
    struct Details: Encodable {
        // Card
        var number: String?
        var cvv: String?
        var expirationMonth: String?
        var expirationYear: String?
        var cardholderName: String?
        // PayPal
        var paypalOrderId: String?
        var paypalBillingAgreementId: String?
        var shippingAddress: ShippingAddress?
        var externalPayerInfo: PayPalExternalPayerInfo?
        // Apple Pay
        var paymentMethodConfigId: String?
        var token: ApplePayPaymentResponseToken?
        var sourceConfig: ApplePaySourceConfig?
        // Direct Debit (GoCardless)
        var gocardlessMandateId: String?
        // Klarna payment session
        var klarnaAuthorizationToken: String?
        // Klarna customer token
        var klarnaCustomerToken: String?
        var sessionData: KlarnaSessionData?
        // Apaya
        var mx: String?
        var mnc: String?
        var mcc: String?
        var hashedIdentifier: String?
        var productId: String?
        var currencyCode: String?
    }
}

protocol PaymentMethodDetailsProtocol: Encodable {}

struct CardDetails: PaymentMethodDetailsProtocol {
    var number: String
    var cvv: String
    var expirationMonth: String
    var expirationYear: String
    var cardholderName: String?
}

struct PayPalDetails: PaymentMethodDetailsProtocol {
    var paypalOrderId: String?
    var paypalBillingAgreementId: String?
    var shippingAddress: ShippingAddress?
    var externalPayerInfo: PayPalExternalPayerInfo?
}

struct ApplePayDetails: PaymentMethodDetailsProtocol {
    var paymentMethodConfigId: String?
    var token: ApplePayPaymentResponseToken?
    var sourceConfig: ApplePaySourceConfig?
}

struct GoCardlessDetails: PaymentMethodDetailsProtocol {
    var gocardlessMandateId: String?
}

struct KlarnaDetails: PaymentMethodDetailsProtocol {
    // Klarna payment session
    var klarnaAuthorizationToken: String?
    // Klarna customer token
    var klarnaCustomerToken: String?
    var sessionData: KlarnaSessionData?
}

struct ApayaDetails: PaymentMethodDetailsProtocol {
    var mx: String
    var mnc: String
    var mcc: String
    var hashedIdentifier: String
    var productId: String
    var currencyCode: String
}

#endif
