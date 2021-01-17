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

extension PaymentMethodConfig {
    func getConfigId(for type: ConfigPaymentMethodType) -> String? {
        guard let method = self.paymentMethods?.first(where: { method in return method.type == type }) else { return nil }
        return method.id
    }
}
