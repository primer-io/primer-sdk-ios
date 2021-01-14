import UIKit

public enum PaymentMethodType {
    case card
    case paypal
    case applepay
}

struct PaymentMethod {
    let type: PaymentMethodType
    var details: PaymentInstrument
}

public struct VaultedPaymentMethodViewModel {
    let id: String
    let last4: String
}
