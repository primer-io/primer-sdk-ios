struct PaymentMethodConfig: Codable {
    let coreUrl: String?
    let pciUrl: String?
    let paymentMethods: [ConfigPaymentMethod]?
}

struct ConfigPaymentMethod: Codable {
    let id: String?
    let type: ConfigPaymentMethodType?
}

enum ConfigPaymentMethodType: String, Codable {
    case APPLE_PAY = "APPLE_PAY"
    case PAYPAL = "PAYPAL"
    case PAYMENT_CARD = "PAYMENT_CARD"
    case GOOGLE_PAY = "GOOGLE_PAY"
}
