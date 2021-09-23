struct PaymentMethodConfig: Codable {
    let coreUrl: String?
    let pciUrl: String?
    let paymentMethods: [ConfigPaymentMethod]?
}

struct ConfigPaymentMethod: Codable {
    let id: String?
    let type: ConfigPaymentMethodType?
    let processorConfigId: String?
    let options: PaymentMethodConfigOptions?
}

enum ConfigPaymentMethodType: String, Codable {
    case applePay = "APPLE_PAY"
    case payPal = "PAYPAL"
    case paymentCard = "PAYMENT_CARD"
    case googlePay = "GOOGLE_PAY"
    case goCardlessMandate = "GOCARDLESS"
    case klarna = "KLARNA"
    case payNlIdeal = "PAY_NL_IDEAL"
    case apaya = "APAYA"
    
    case unknown
    
    var isEnabled: Bool {
        switch self {
        case .applePay, .payPal, .paymentCard, .goCardlessMandate, .klarna, .apaya:
            return true
        default:
            return false
        }
    }
}

internal extension PaymentMethodConfig {
    func getConfigId(for type: ConfigPaymentMethodType) -> String? {
        guard let method = self.paymentMethods?
                .first(where: { method in return method.type == type }) else { return nil }
        return method.id
    }
    
    func getConfigId(forName name: String) -> String? {
        guard let configPaymentMethodType = ConfigPaymentMethodType(rawValue: name) else { return nil }
        return getConfigId(for: configPaymentMethodType)
    }
    
    func getProductId(for type: ConfigPaymentMethodType) -> String? {
        guard let method = self.paymentMethods?
                .first(where: { method in return method.type == type }) else { return nil }
        return method.options?.merchantAccountId
    }
    
    func getProductId(forName name: String) -> String? {
        guard let configPaymentMethodType = ConfigPaymentMethodType(rawValue: name) else { return nil }
        return getProductId(for: configPaymentMethodType)
    }
}

class PaymentMethodConfigOptions: Codable {
    let merchantAccountId: String?
    
    init(merchantAccountId: String?) {
        self.merchantAccountId = merchantAccountId
    }
}
