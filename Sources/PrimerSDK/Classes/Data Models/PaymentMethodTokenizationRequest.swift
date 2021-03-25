#if canImport(UIKit)

import Foundation

struct PaymentMethodTokenizationRequest: Encodable {
    let paymentInstrument: PaymentInstrument
    let tokenType: TokenType?
    let paymentFlow: PaymentFlow?
    let customerId: String?
    
    init(paymentInstrument: PaymentInstrument, state: AppStateProtocol) {
        self.paymentInstrument = paymentInstrument
        self.tokenType = .multiUse
        self.paymentFlow = PaymentFlow.vault
        self.customerId = state.settings.customerId
    }

}

struct PaymentInstrument: Encodable {
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
    var token: ApplePayToken?
    var merchantIdentifier: String?
    // Direct Debit (GoCardless)
    var gocardlessMandateId: String?
    // Klarna payment session
    var klarnaAuthorizationToken: String?
    var sessionData: KlarnaSessionData?
}

enum TokenType: String, Encodable {
    case multiUse = "MULTI_USE"
    case singleUse = "SINGLE_USE"
}

enum PaymentFlow: String, Encodable {
    case vault = "VAULT"
}

#endif
