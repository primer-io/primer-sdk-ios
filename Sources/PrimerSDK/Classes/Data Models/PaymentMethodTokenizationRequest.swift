#if canImport(UIKit)

// feels like we could polymorph this with a protocol, or at least restrict construcions with a specific factory method for each payment instrument.
//struct PaymentInstrument: Codable {
//    // Card
//    var number: String?
//    var cvv: String?
//    var expirationMonth: String?
//    var expirationYear: String?
//    var cardholderName: String?
//    // PayPal
//    var paypalOrderId: String?
//    var paypalBillingAgreementId: String?
//    var shippingAddress: PaymentMethod.PayPal.ShippingAddress?
//    var externalPayerInfo: PaymentMethod.PayPal.ExternalPayerInfo?
//    // Apple Pay
//    var paymentMethodConfigId: String?
//    var token: ApplePayPaymentResponseToken?
//    var sourceConfig: ApplePaySourceConfig?
//    // Direct Debit (GoCardless)
//    var gocardlessMandateId: String?
//    // Klarna payment session
//    var klarnaAuthorizationToken: String?
//    // Klarna customer token
//    var klarnaCustomerToken: String?
//    var sessionData: KlarnaSessionData?
//    // Apaya
//    var mx: String?
//    var mnc: String?
//    var mcc: String?
//    var hashedIdentifier: String?
//    var productId: String?
//    var currencyCode: String?
//    // DotPay
//    var sessionInfo: PaymentMethod.DotPay.SessionInfo?
//    var type: String?
//    var paymentMethodType: String?
//}

struct ApplePaySourceConfig: Codable {
    let source: String
    let merchantId: String
}

struct PayPal {
    struct PayerInfo {
        struct Request: Codable {
            let paymentMethodConfigId: String
            let orderId: String
        }
        
        struct Response: Codable {
            let orderId: String
            let externalPayerInfo: PaymentMethod.PayPal.ExternalPayerInfo
        }
    }
}

#endif
