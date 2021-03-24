
#if canImport(UIKit)

import Foundation

struct PaymentMethodTokenizationRequest: Encodable {
    let paymentInstrument: PaymentInstrument
    let tokenType: TokenType?
    let paymentFlow: PaymentFlow?
    let customerId: String?
    var path: String = "/payment-instruments"
    
    init(paymentInstrument: PaymentInstrument, state: AppStateProtocol) {
        self.paymentInstrument = paymentInstrument
        self.tokenType = .multiUse
        self.paymentFlow = PaymentFlow.vault
        self.customerId = state.settings.customerId
    }
    
}

struct PaymentInstrument: Encodable {
    // Card
    var number: String? = nil
    var cvv: String? = nil
    var expirationMonth: String? = nil
    var expirationYear: String? = nil
    var cardholderName: String? = nil
    // PayPal
    var paypalOrderId: String? = nil
    var paypalBillingAgreementId: String? = nil
    var shippingAddress: ShippingAddress? = nil
    var externalPayerInfo: PayPalExternalPayerInfo? = nil
    // Apple Pay
    var paymentMethodConfigId: String? = nil
    var token: ApplePayToken? = nil
    var merchantIdentifier: String? = nil
    // Direct Debit (GoCardless)
    var gocardlessMandateId: String? = nil
    // Klarna payment session
    var klarnaAuthorizationToken: String? = nil
    var sessionData: KlarnaSessionData? = nil
}

enum TokenType: String, Encodable {
    case multiUse = "MULTI_USE"
    case singleUse = "SINGLE_USE"
}

enum PaymentFlow: String, Encodable {
    case vault = "VAULT"
}

#endif
