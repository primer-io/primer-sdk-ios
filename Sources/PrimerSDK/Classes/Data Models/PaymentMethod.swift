#if canImport(UIKit)

import UIKit

public enum PaymentMethodType {
    case card
    case paypal
    case applepay
    case apaya
}

protocol PaymentMethodDetailsProtocol: Encodable {

}

struct PaymentMethod {
    let type: PaymentMethodType
    var details: PaymentMethodDetailsProtocol
    
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
}

#endif
