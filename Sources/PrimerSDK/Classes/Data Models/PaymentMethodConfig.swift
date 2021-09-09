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

public enum ConfigPaymentMethodType: String, Codable {
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
    
    func getProductId(for type: ConfigPaymentMethodType) -> String? {
        guard let method = self.paymentMethods?
                .first(where: { method in return method.type == type }) else { return nil }
        return method.options?.merchantAccountId
    }
}

class PaymentMethodConfigOptions: Codable {
    let merchantAccountId: String?
    
    init(merchantAccountId: String?) {
        self.merchantAccountId = merchantAccountId
    }
}
