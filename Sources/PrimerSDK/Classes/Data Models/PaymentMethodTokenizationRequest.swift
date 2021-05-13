#if canImport(UIKit)

struct PaymentMethodTokenizationRequest: Encodable {
    
    let paymentInstrument: PaymentInstrument
    let tokenType: TokenType?
    let paymentFlow: PaymentFlow?
    let customerId: String?

    init(paymentInstrument: PaymentInstrument, state: AppStateProtocol) {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        self.paymentInstrument = paymentInstrument
        self.tokenType = Primer.shared.flow.vaulted ? .multiUse : .singleUse
        self.paymentFlow = Primer.shared.flow.vaulted ? .vault : nil
        self.customerId = Primer.shared.flow.vaulted ? settings.customerId : nil
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
    var token: ApplePayPaymentResponseToken?
    var sourceConfig: ApplePaySourceConfig?
    // Direct Debit (GoCardless)
    var gocardlessMandateId: String?
    // Klarna payment session
    var klarnaAuthorizationToken: String?
    // Klarna customer token
    var klarnaCustomerToken: String?
    var sessionData: KlarnaSessionData?
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
