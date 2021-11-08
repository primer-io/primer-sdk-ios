#if canImport(UIKit)

struct PrimerConfiguration: Codable {
    
    static var paymentMethodConfigViewModels: [PaymentMethodTokenizationViewModelProtocol] {
        let state: AppStateProtocol = DependencyContainer.resolve()
        var viewModels = state
            .paymentMethodConfig?
            .paymentMethods?
            .filter({ $0.type.isEnabled })
            .compactMap({ $0.tokenizationViewModel })
        ?? []
        
        for (index, viewModel) in viewModels.enumerated() {
            if viewModel.config.type == .applePay {
                viewModels.swapAt(0, index)
            }
        }
        
        for (index, viewModel) in viewModels.enumerated() {
            viewModel.position = index
        }
        
        return viewModels
    }
    
    let coreUrl: String?
    let pciUrl: String?
    let paymentMethods: [PaymentMethodConfig]?
    let keys: ThreeDS.Keys?
    
    func getConfigId(for type: PaymentMethodConfigType) -> String? {
        guard let method = self.paymentMethods?.filter({ $0.type == type }).first else { return nil }
        return method.id
    }
    
    func getProductId(for type: PaymentMethodConfigType) -> String? {
        guard let method = self.paymentMethods?
                .first(where: { method in return method.type == type }) else { return nil }
        
        if let apayaOptions = method.options as? ApayaOptions {
            return apayaOptions.merchantAccountId
        } else {
            return nil
        }
    }
}

struct PaymentMethodConfig: Codable {
    
    let id: String? // Will be nil for cards
    let processorConfigId: String?
    let type: PaymentMethodConfigType
    let options: PaymentMethodOptions?
    var tokenizationViewModel: PaymentMethodTokenizationViewModelProtocol? {
        if type == .paymentCard {
            return CardFormPaymentMethodTokenizationViewModel(config: self)
        } else if type == .applePay {
            if #available(iOS 11.0, *) {
                return ApplePayTokenizationViewModel(config: self)
            }
        } else if type == .klarna {
            return KlarnaTokenizationViewModel(config: self)
        } else if type == .hoolah || type == .payNLIdeal {
            return ExternalPaymentMethodTokenizationViewModel(config: self)
        } else if type == .payPal {
            return PayPalTokenizationViewModel(config: self)
        } else if type == .apaya {
            return ApayaTokenizationViewModel(config: self)
        } else if type == .dotPay {
            return DotPayTokenizationViewModel(config: self)
        }
        
        return nil
    }
    
    private enum CodingKeys : String, CodingKey {
        case id, options, processorConfigId, type
    }
    
    init(id: String?, options: PaymentMethodOptions?, processorConfigId: String?, type: PaymentMethodConfigType) {
        self.id = id
        self.options = options
        self.processorConfigId = processorConfigId
        self.type = type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String?.self, forKey: .id)
        processorConfigId = try container.decode(String?.self, forKey: .processorConfigId)
        type = try container.decode(PaymentMethodConfigType.self, forKey: .type)
        
        if let cardOptions = try? container.decode(CardOptions.self, forKey: .options) {
            options = cardOptions
        } else if let payPalOptions = try? container.decode(PayPalOptions.self, forKey: .options) {
            options = payPalOptions
        } else if let apayaOptions = try? container.decode(ApayaOptions.self, forKey: .options) {
            options = apayaOptions
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

struct ApayaOptions: PaymentMethodOptions {
    let merchantAccountId: String
}

struct PayPalOptions: PaymentMethodOptions {
    let clientId: String
}

struct CardOptions: PaymentMethodOptions {
    let threeDSecureEnabled: Bool
    let threeDSecureToken: String?
    let threeDSecureInitUrl: String?
    let threeDSecureProvider: String
    let processorConfigId: String?
}

struct AsyncPaymentMethodOptions: PaymentMethodOptions {
    let type: String = "OFF_SESSION_PAYMENT"
    let paymentMethodType: PaymentMethodConfigType
    let paymentMethodConfigId: String
}

public enum PaymentMethodConfigType: String, Codable {
    case applePay = "APPLE_PAY"
    case payPal = "PAYPAL"
    case paymentCard = "PAYMENT_CARD"
    case googlePay = "GOOGLE_PAY"
    case goCardlessMandate = "GOCARDLESS"
    case klarna = "KLARNA"
    case payNLIdeal = "PAY_NL_IDEAL"
    case apaya = "APAYA"
    case hoolah = "HOOLAH"
    case dotPay = "ADYEN_DOTPAY"
    
    case unknown
    
    var isEnabled: Bool {
        switch self {
        case .goCardlessMandate,
                .googlePay:
            return false
        case .paymentCard,
                .payPal:
            return true
        case .apaya,
                .klarna:
            return Primer.shared.flow.internalSessionFlow.vaulted
        case .applePay,
                .hoolah,
                .payNLIdeal,
                .dotPay:
            return !Primer.shared.flow.internalSessionFlow.vaulted
        case .unknown:
            return false
        }
    }
    
    public init(from decoder: Decoder) throws {
        self = ((try? PaymentMethodConfigType(rawValue: decoder.singleValueContainer().decode(RawValue.self))) ?? nil) ?? .unknown
    }
}

public enum PayType {
    case applePay, payPal, paymentCard, googlePay, goCardless, klarna,
         payNLIdeal, apaya, hoolah
    case other(value: String)
    
    init(rawValue: String) {
        switch rawValue {
        case "APAYA":
            self = .apaya
        case "APPLE_PAY":
            self = .applePay
        case "GOCARDLESS":
            self = .goCardless
        case "GOOGLE_PAY":
            self = .googlePay
        default:
            self = .other(value: rawValue)
        }
    }
}

#endif
