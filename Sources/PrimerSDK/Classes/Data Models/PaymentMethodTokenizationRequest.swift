#if canImport(UIKit)

protocol TokenizationRequest: Encodable {}

struct PaymentMethodTokenizationRequest: TokenizationRequest {
    
    let paymentInstrument: PaymentInstrument
    let tokenType: TokenType?
    let paymentFlow: PrimerSessionIntent?

    init(paymentInstrument: PaymentInstrument, state: AppStateProtocol?) {
        self.paymentInstrument = paymentInstrument
        self.tokenType = Primer.shared.intent == .vault ? .multiUse : nil
        self.paymentFlow = Primer.shared.intent == .vault ? .vault : nil
    }
    
    init(paymentInstrument: PaymentInstrument, paymentFlow: PrimerSessionIntent?) {
        self.paymentInstrument = paymentInstrument
        self.paymentFlow = (paymentFlow == .vault) ? .vault : nil
        self.tokenType = (paymentFlow == .vault) ? .multiUse : nil
    }

}

struct AsyncPaymentMethodTokenizationRequest: TokenizationRequest {
    let paymentInstrument: AsyncPaymentMethodOptions
}

struct BankSelectorTokenizationRequest: TokenizationRequest {
    let paymentInstrument: PaymentInstrument
}

struct TestPaymentMethodTokenizationRequest: TokenizationRequest {
    let paymentInstrument: PrimerTestPaymentMethodOptions
}

struct BlikPaymentMethodTokenizationRequest: TokenizationRequest {
    let paymentInstrument: BlikPaymentMethodOptions
}

struct InputPhoneNumberPaymentMethodTokenizationRequest: TokenizationRequest {
    let paymentInstrument: InputPhoneNumberPaymentMethodOptions
}

// feels like we could polymorph this with a protocol, or at least restrict construcions with a specific factory method for each payment instrument.
struct PaymentInstrument: Codable {
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
    var externalPayerInfo: ExternalPayerInfo?
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
    // DotPay
    var sessionInfo: BankSelectorSessionInfo?
    var type: String?
    var paymentMethodType: String?
}

internal struct BankSelectorSessionInfo: Codable {
    var issuer: String?
    var locale: String = "en_US"
    var platform: String = "IOS"
}

public enum TokenType: String, Codable {
    case multiUse = "MULTI_USE"
    case singleUse = "SINGLE_USE"
}

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
            let externalPayerInfo: ExternalPayerInfo
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

#endif
