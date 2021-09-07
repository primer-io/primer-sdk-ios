#if canImport(UIKit)

import UIKit

protocol PaymentMethodDetailsProtocol: Codable {

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
        
    var isEnabled: Bool {
        switch self {
        case .applePay, .payPal, .card, .goCardless, .klarna, .apaya:
            return true
        default:
            return false
        }
    }
}

//class PaymentMethodDetails: Encodable, PaymentMethodDetailsProtocol {}
//
//class CardDetails: PaymentMethodDetails {
//
//}

struct PaymentMethod {
    
    let type: PaymentMethodType
    var details: PaymentMethodDetailsProtocol
    
    struct Card: Codable {
        class Details: PaymentMethodDetailsProtocol {
            var number: String
            var cvv: String
            var expirationMonth: String
            var expirationYear: String
            var cardholderName: String?
            
            init(
                number: String,
                cvv: String,
                expirationMonth: String,
                expirationYear: String,
                cardholderName: String? = nil
            ) {
                self.number = number
                self.cvv = cvv
                self.expirationMonth = expirationMonth
                self.expirationYear = expirationYear
                self.cardholderName = cardholderName
            }
        }
    }

    struct PayPal: Codable {
        class Details: PaymentMethodDetailsProtocol {
            var paypalOrderId: String?
            var paypalBillingAgreementId: String?
            var shippingAddress: ShippingAddress?
            var externalPayerInfo: PayPalExternalPayerInfo?
            
            init(
                paypalOrderId: String? = nil,
                paypalBillingAgreementId: String? = nil,
                shippingAddress: ShippingAddress? = nil,
                externalPayerInfo: PayPalExternalPayerInfo? = nil
            ) {
                self.paypalOrderId = paypalOrderId
                self.paypalBillingAgreementId = paypalBillingAgreementId
                self.shippingAddress = shippingAddress
                self.externalPayerInfo = externalPayerInfo
            }
        }
    }

    struct ApplePay: Codable {
        class Details: PaymentMethodDetailsProtocol {
            var paymentMethodConfigId: String?
            var token: ApplePayPaymentResponseToken?
            var sourceConfig: ApplePaySourceConfig?
            
            init(
                paymentMethodConfigId: String? = nil,
                token: ApplePayPaymentResponseToken? = nil,
                sourceConfig: ApplePaySourceConfig? = nil
            ) {
                self.paymentMethodConfigId = paymentMethodConfigId
                self.token = token
                self.sourceConfig = sourceConfig
            }
        }
        
        struct ApplePaySourceConfig: Codable {
            let source: String
            let merchantId: String
        }
    }

    struct GoCardless: Codable {
        class Details: PaymentMethodDetailsProtocol {
            var gocardlessMandateId: String
            
            init(gocardlessMandateId: String) {
                self.gocardlessMandateId = gocardlessMandateId
            }
        }
    }

    struct Klarna: Codable {
        class Details: PaymentMethodDetailsProtocol {
            // Klarna payment session
            var klarnaAuthorizationToken: String?
            // Klarna customer token
            var klarnaCustomerToken: String?
            var sessionData: KlarnaSessionData?
            
            init(
                klarnaAuthorizationToken: String? = nil,
                klarnaCustomerToken: String? = nil,
                sessionData: KlarnaSessionData? = nil
            ) {
                self.klarnaAuthorizationToken = klarnaAuthorizationToken
                self.klarnaCustomerToken = klarnaCustomerToken
                self.sessionData = sessionData
            }
        }
    }

    struct Apaya: Codable {
        class Details: PaymentMethodDetailsProtocol {
            var mx: String
            var mnc: String
            var mcc: String
            var hashedIdentifier: String
            var productId: String
            var currencyCode: String
            
            init(
                mx: String,
                mnc: String,
                mcc: String,
                hashedIdentifier: String,
                productId: String,
                currencyCode: String
            ) {
                self.mx = mx
                self.mnc = mnc
                self.mcc = mcc
                self.hashedIdentifier = hashedIdentifier
                self.productId = productId
                self.currencyCode = currencyCode
            }
        }
    }
}

#endif
