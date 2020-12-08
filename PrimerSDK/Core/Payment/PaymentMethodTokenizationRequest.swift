import Foundation

struct PaymentMethodTokenizationRequest: Encodable {
    let paymentInstrument: PaymentInstrument
    let tokenType: String
    let paymentFlow: String
    let customerId: String
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
