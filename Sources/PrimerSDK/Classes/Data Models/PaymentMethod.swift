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
    
    struct Card {
        struct Details: PaymentMethodDetailsProtocol {
            var number: String
            var cvv: String
            var expirationMonth: String
            var expirationYear: String
            var cardholderName: String?
        }
    }

    struct PayPal {
        struct Details: PaymentMethodDetailsProtocol {
            var paypalOrderId: String?
            var paypalBillingAgreementId: String?
            var shippingAddress: ShippingAddress?
            var externalPayerInfo: PayPalExternalPayerInfo?
        }
    }

    struct ApplePay {
        struct Details: PaymentMethodDetailsProtocol {
            var paymentMethodConfigId: String?
            var token: ApplePayPaymentResponseToken?
            var sourceConfig: ApplePaySourceConfig?
        }
        
        struct ApplePaySourceConfig: Codable {
            let source: String
            let merchantId: String
        }
    }

    struct GoCardless {
        struct Details: PaymentMethodDetailsProtocol {
            var gocardlessMandateId: String?
        }
    }

    struct Klarna {
        struct Details: PaymentMethodDetailsProtocol {
            // Klarna payment session
            var klarnaAuthorizationToken: String?
            // Klarna customer token
            var klarnaCustomerToken: String?
            var sessionData: KlarnaSessionData?
        }
    }

    struct Apaya {
        struct Details: PaymentMethodDetailsProtocol {
            var mx: String
            var mnc: String
            var mcc: String
            var hashedIdentifier: String
            var productId: String
            var currencyCode: String
        }
    }
}

#endif
