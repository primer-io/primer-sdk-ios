import Foundation

struct PaymentMethodTokenizationRequest: Encodable {
    let paymentInstrument: PaymentInstrument
    let tokenType: TokenType?
    let paymentFlow: PaymentFlow?
    let customerId: String?
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
}

enum TokenType: String, Encodable {
    case multiUse = "MULTI_USE"
    case singleUse = "SINGLE_USE"
}

enum PaymentFlow: String, Encodable {
    case vault = "VAULT"
}
