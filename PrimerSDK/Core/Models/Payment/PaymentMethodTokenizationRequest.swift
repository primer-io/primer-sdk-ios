import Foundation

struct PaymentMethodTokenizationRequest: Encodable {
    let paymentInstrument: PaymentInstrument
    let tokenType: TokenType?
    let paymentFlow: PaymentFlow?
    let customerId: String?
    
    init(
        with uxMode: UXMode,
        and customerId: String,
        and paymentInstrument: PaymentInstrument
    ) {
        self.paymentInstrument = paymentInstrument
        self.tokenType = uxMode == .VAULT ? .multiUse : .singleUse
        self.paymentFlow = uxMode == .VAULT ? PaymentFlow.vault : nil
        self.customerId = uxMode == .VAULT ? customerId : nil
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
}

enum TokenType: String, Encodable {
    case multiUse = "MULTI_USE"
    case singleUse = "SINGLE_USE"
}

enum PaymentFlow: String, Encodable {
    case vault = "VAULT"
}
