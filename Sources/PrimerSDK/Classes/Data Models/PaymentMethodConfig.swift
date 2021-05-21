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
    case applePay = "APPLE_PAY"
    case payPal = "PAYPAL"
    case paymentCard = "PAYMENT_CARD"
    case googlePay = "GOOGLE_PAY"
    case goCardlessMandate = "GOCARDLESS"
    case klarna = "KLARNA"
}

internal extension PaymentMethodConfig {
    func getConfigId(for type: ConfigPaymentMethodType) -> String? {
        guard let method = self.paymentMethods?.first(where: { method in return method.type == type }) else { return nil }
        return method.id
    }
}
