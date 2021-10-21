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
        
        let twintViewModel: PaymentMethodTokenizationViewModelProtocol = ExternalPaymentMethodTokenizationViewModel(
            config: PaymentMethodConfig(
                id: "twint",
                options: nil,
                processorConfigId: "processor",
                type: .twint))
        
        viewModels.append(twintViewModel)
        
        let sofortViewModel: PaymentMethodTokenizationViewModelProtocol = ExternalPaymentMethodTokenizationViewModel(
            config: PaymentMethodConfig(
                id: "sofort",
                options: nil,
                processorConfigId: "processor",
                type: .sofort))
        
        viewModels.append(sofortViewModel)
        
        let giropayViewModel: PaymentMethodTokenizationViewModelProtocol = ExternalPaymentMethodTokenizationViewModel(
            config: PaymentMethodConfig(
                id: "giropay",
                options: nil,
                processorConfigId: "processor",
                type: .giropay))
        
        viewModels.append(giropayViewModel)
        
        let alipayViewModel: PaymentMethodTokenizationViewModelProtocol = ExternalPaymentMethodTokenizationViewModel(
            config: PaymentMethodConfig(
                id: "alipay",
                options: nil,
                processorConfigId: "processor",
                type: .aliPay))
        
        viewModels.append(alipayViewModel)
        
        let trustlyViewModel: PaymentMethodTokenizationViewModelProtocol = ExternalPaymentMethodTokenizationViewModel(
            config: PaymentMethodConfig(
                id: "trustly",
                options: nil,
                processorConfigId: "processor",
                type: .trustly))
        
        viewModels.append(trustlyViewModel)
        
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

public enum PaymentMethodConfigType: Codable, Equatable /*: String, Codable*/ {
    case aliPay
    case apaya
    case applePay
    case giropay
    case googlePay
    case goCardlessMandate
    case hoolah
    case klarna
    case payNLIdeal
    case paymentCard
    case payPal
    case sofort
    case trustly
    case twint
    case other(rawValue: String)
    
    init(rawValue: String) {
        switch rawValue {
        case "ADYEN_ALIPAY":
            self = .aliPay
        case "APAYA":
            self = .apaya
        case "APPLE_PAY":
            self = .applePay
        case "ADYEN_GIROPAY":
            self = .giropay
        case "GOCARDLESS":
            self = .goCardlessMandate
        case "GOOGLE_PAY":
            self = .googlePay
        case "HOOLAH":
            self = .hoolah
        case "KLARNA":
            self = .klarna
        case "PAY_NL_IDEAL":
            self = .payNLIdeal
        case "PAYMENT_CARD":
            self = .paymentCard
        case "PAYPAL":
            self = .payPal
        case "ADYEN_SOFORT_BANKING":
            self = .sofort
        case "ADYEN_TRUSTLY":
            self = .trustly
        case "ADYEN_TWINT":
            self = .twint
        default:
            self = .other(rawValue: rawValue)
        }
    }
    
    var rawValue: String {
        switch self {
        case .aliPay:
            return "ADYEN_ALIPAY"
        case .apaya:
            return "APAYA"
        case .applePay:
            return "APPLE_PAY"
        case .giropay:
            return "ADYEN_GIROPAY"
        case .goCardlessMandate:
            return "GOCARDLESS"
        case .googlePay:
            return "GOOGLE_PAY"
        case .hoolah:
            return "HOOLAH"
        case .klarna:
            return "KLARNA"
        case .payNLIdeal:
            return "PAY_NL_IDEAL"
        case .paymentCard:
            return "PAYMENT_CARD"
        case .payPal:
            return "PAYPAL"
        case .sofort:
            return "ADYEN_SOFORT_BANKING"
        case .trustly:
            return "ADYEN_TRUSTLY"
        case .twint:
            return "ADYEN_TWINT"
        case .other(let rawValue):
            return rawValue
        }
    }
    
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
        case .aliPay,
                .applePay,
                .giropay,
                .hoolah,
                .payNLIdeal,
                .sofort,
                .trustly,
                .twint:
            return !Primer.shared.flow.internalSessionFlow.vaulted
        case .other:
            return false
        }
    }
    
    public init(from decoder: Decoder) throws {
        let rawValue: String = try decoder.singleValueContainer().decode(String.self)
        self = PaymentMethodConfigType(rawValue: rawValue)
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
