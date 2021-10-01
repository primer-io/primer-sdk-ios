struct PaymentMethodConfig: Codable {
    let coreUrl: String?
    let pciUrl: String?
    let clientSession: ClientSession?
    let paymentMethods: [ConfigPaymentMethod]?
    var isSetByClientSession: Bool {
        return clientSession != nil
    }
    
    enum CodingKeys: String, CodingKey {
        case coreUrl, pciUrl, clientSession, paymentMethods
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.coreUrl = try? container.decode(String?.self, forKey: .coreUrl)
        self.pciUrl = try? container.decode(String?.self, forKey: .pciUrl)
        self.clientSession = try? container.decode(ClientSession?.self, forKey: .clientSession)
        self.paymentMethods = try? container.decode([ConfigPaymentMethod]?.self, forKey: .paymentMethods)
    }
    
    init(
        coreUrl: String?,
        pciUrl: String?,
        clientSession: ClientSession?,
        paymentMethods: [ConfigPaymentMethod]?
    ) {
        self.coreUrl = coreUrl
        self.pciUrl = pciUrl
        self.clientSession = clientSession
        self.paymentMethods = paymentMethods
    }
}

struct ConfigPaymentMethod: Codable {
    let id: String?
    let type: ConfigPaymentMethodType?
    let processorConfigId: String?
    let options: PaymentMethodConfigOptions?
    
    enum CodingKeys: String, CodingKey {
        case id, type, processorConfigId, options
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try? container.decode(String.self, forKey: .id)
        self.type = try? container.decode(ConfigPaymentMethodType?.self, forKey: .type)
        self.processorConfigId = try? container.decode(String?.self, forKey: .processorConfigId)
        self.options = try? container.decode(PaymentMethodConfigOptions?.self, forKey: .options)
    }
    
    init(
        id: String?,
        type: ConfigPaymentMethodType?,
        processorConfigId: String?,
        options: PaymentMethodConfigOptions?
    ) {
        self.id = id
        self.type = type
        self.processorConfigId = processorConfigId
        self.options = options
    }
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
    
    public init(from decoder: Decoder) throws {
        self = (try? ConfigPaymentMethodType(rawValue: decoder.singleValueContainer().decode(RawValue.self))) ?? .unknown
    }
}

internal extension PaymentMethodConfig {
    func getConfig(for type: ConfigPaymentMethodType) -> ConfigPaymentMethod? {
        // guard let method = self.paymentMethods?.filter({ $0.type == type }).first else { return nil }
        // return (type == .paymentCard && method.id == nil) ? ConfigPaymentMethodType.paymentCard.rawValue : method.id
        guard let method = self.paymentMethods?.filter({ $0.type == type }).first else { return nil }
        return method
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
