struct PaymentMethodConfig: Codable {
    let coreUrl: String?
    let pciUrl: String?
    let paymentMethods: [ConfigPaymentMethod]?
    let env: String?
    let keys: ThreeDS.Keys?
}

struct ConfigPaymentMethod: Codable {
    
    let id: String?
    let options: PaymentMethodOptions?
    let processorConfigId: String?
    let type: ConfigPaymentMethodType?
    
    private enum CodingKeys : String, CodingKey {
        case id, options, processorConfigId, type
    }
    
    init(id: String?, options: PaymentMethodOptions?, processorConfigId: String?, type: ConfigPaymentMethodType) {
        self.id = id
        self.options = options
        self.processorConfigId = processorConfigId
        self.type = type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String?.self, forKey: .id)
        processorConfigId = try container.decode(String?.self, forKey: .processorConfigId)
        type = try container.decode(ConfigPaymentMethodType?.self, forKey: .type)
        
        if let cardOptions = try? container.decode(CardOptions.self, forKey: .options) {
            options = cardOptions
        } else if let payPalOptions = try? container.decode(PayPalOptions.self, forKey: .options) {
            options = payPalOptions
        } else {
            options = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(processorConfigId, forKey: .processorConfigId)
        try container.encode(type, forKey: .type)
        
        if let cardOptions = options as? CardOptions {
            try container.encode(cardOptions, forKey: .options)
        } else if let payPalOptions = options as? PayPalOptions {
            try container.encode(payPalOptions, forKey: .options)
        }
    }
    
}

protocol PaymentMethodOptions: Codable { }

extension PaymentMethodOptions { }

struct PayPalOptions: PaymentMethodOptions {
    let clientId: String
}

struct CardOptions: PaymentMethodOptions {
    let threeDSecureEnabled: Bool
    let threeDSecureToken: String?
    let threeDSecureInitUrl: String?
    let threeDSecureProvider: String
}

enum ConfigPaymentMethodType: String, Codable {
    case applePay = "APPLE_PAY"
    case payPal = "PAYPAL"
    case paymentCard = "PAYMENT_CARD"
    case googlePay = "GOOGLE_PAY"
    case goCardlessMandate = "GOCARDLESS"
    case klarna = "KLARNA"
    case payNlIdeal = "PAY_NL_IDEAL"
    
    case unknown
    
    var isEnabled: Bool {
        switch self {
        case .applePay, .payPal, .paymentCard, .goCardlessMandate, .klarna:
            return true
        default:
            return false
        }
    }
}

internal extension PaymentMethodConfig {
    func getConfigId(for type: ConfigPaymentMethodType) -> String? {
        guard let method = self.paymentMethods?.first(where: { method in return method.type == type }) else { return nil }
        return method.id
    }
}
