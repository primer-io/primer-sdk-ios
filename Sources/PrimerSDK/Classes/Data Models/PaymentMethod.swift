#if canImport(UIKit)

import UIKit

protocol PaymentMethodDetailsProtocol: Encodable {

}

enum PaymentMethodType: String, Codable {
    case applePay = "APPLE_PAY"
    case payPal = "PAYPAL"
    case card = "PAYMENT_CARD"
    case googlePay = "GOOGLE_PAY"
    case goCardless = "GOCARDLESS"
    case klarna = "KLARNA"
    case payNlIdeal = "PAY_NL_IDEAL"
    case apaya = "APAYA"
    
    case unknown
    
    var isEnabled: Bool {
        switch self {
        case .applePay, .payPal, .card, .goCardless, .klarna, .apaya:
            return true
        default:
            return false
        }
    }
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
