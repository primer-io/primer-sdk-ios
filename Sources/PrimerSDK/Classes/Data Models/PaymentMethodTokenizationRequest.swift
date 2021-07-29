#if canImport(UIKit)

struct PaymentMethodTokenizationRequest: Encodable {
    
    let paymentInstrument: PaymentInstrument
    let tokenType: TokenType
    let paymentFlow: PaymentFlow?
    let customerId: String?

    init(paymentInstrument: PaymentInstrument, state: AppStateProtocol) {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        self.paymentInstrument = paymentInstrument
        self.tokenType = Primer.shared.flow.internalSessionFlow.vaulted ? .multiUse : .singleUse
        self.paymentFlow = Primer.shared.flow.internalSessionFlow.vaulted ? .vault : nil
        self.customerId = Primer.shared.flow.internalSessionFlow.vaulted ? settings.customerId : nil
    }

}

// feels like we could polymorph this with a protocol, or at least restrict construcions with a specific factory method for each payment instrument.
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
    var apayaToken: String?
    var apayaMxValue: String?
}

enum TokenType: String, Encodable {
    case multiUse = "MULTI_USE"
    case singleUse = "SINGLE_USE"
}

enum PaymentFlow: String, Encodable {
    case vault = "VAULT"
}

struct ApplePaySourceConfig: Codable {
    let source: String
    let merchantId: String
}

#endif
