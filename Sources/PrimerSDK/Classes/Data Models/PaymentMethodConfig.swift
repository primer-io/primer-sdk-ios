#if canImport(UIKit)

struct PrimerConfiguration: Codable {
    
    static var paymentMethodConfigViewModels: [PaymentMethodTokenizationViewModelProtocol] {
        if Primer.shared.flow == nil { return [] }
        
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        let paymentMethods = state
            .paymentMethodConfig?
            .paymentMethods
        
        var viewModels = paymentMethods?
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
        let asyncPaymentMethodTypes: [PaymentMethodConfigType] = [
            .adyenMobilePay,
            .adyenVipps,
            .adyenAlipay,
            .adyenGiropay,
            .mollieIdeal,
            .payNLGiropay,
            .payNLPayconiq,
            .adyenSofortBanking,
            .adyenTrustly,
            .adyenTwint
        ]
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
        } else if asyncPaymentMethodTypes.contains(type) {
            return ExternalPaymentMethodTokenizationViewModel(config: self)
        }
        
        log(logLevel: .info, title: "UNHANDLED PAYMENT METHOD TYPE", message: type.rawValue, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: #function, line: nil)

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
    
    let paymentMethodType: PaymentMethodConfigType
    let paymentMethodConfigId: String
    let type: String = "OFF_SESSION_PAYMENT"
    let sessionInfo: SessionInfo?
    
    private enum CodingKeys : String, CodingKey {
        case type, paymentMethodType, paymentMethodConfigId, sessionInfo
    }
    
    init(
        paymentMethodType: PaymentMethodConfigType,
        paymentMethodConfigId: String,
        sessionInfo: SessionInfo?
    ) {
        self.paymentMethodType = paymentMethodType
        self.paymentMethodConfigId = paymentMethodConfigId
        self.sessionInfo = sessionInfo
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(paymentMethodType.rawValue, forKey: .paymentMethodType)
        try container.encode(paymentMethodConfigId, forKey: .paymentMethodConfigId)
        try? container.encode(sessionInfo, forKey: .sessionInfo)
    }
    
    struct SessionInfo: Codable {
        let locale: String
        let platform: String = "IOS"
    }
    
}

public enum PaymentMethodConfigType: Codable, Equatable {
    
    case adyenAlipay
    case adyenGiropay
    case adyenMobilePay
    case adyenSofortBanking
    case adyenTrustly
    case adyenTwint
    case adyenVipps
    case apaya
    case applePay
    case goCardlessMandate
    case googlePay
    case hoolah
    case klarna
    case mollieIdeal
    case payNLGiropay
    case payNLIdeal
    case payNLPayconiq
    case paymentCard
    case payPal
    case other(rawValue: String)
    
    init(rawValue: String) {
        switch rawValue {
        case "ADYEN_ALIPAY":
            self = .adyenAlipay
        case "ADYEN_GIROPAY":
            self = .adyenGiropay
        case "ADYEN_MOBILEPAY":
            self = .adyenMobilePay
        case "ADYEN_SOFORT_BANKING":
            self = .adyenSofortBanking
        case "ADYEN_TRUSTLY":
            self = .adyenTrustly
        case "ADYEN_TWINT":
            self = .adyenTwint
        case "ADYEN_VIPPS":
            self = .adyenVipps
        case "APAYA":
            self = .apaya
        case "APPLE_PAY":
            self = .applePay
        case "GOCARDLESS":
            self = .goCardlessMandate
        case "GOOGLE_PAY":
            self = .googlePay
        case "HOOLAH":
            self = .hoolah
        case "KLARNA":
            self = .klarna
        case "MOLLIE_IDEAL":
            self = .mollieIdeal
        case "PAY_NL_GIROPAY":
            self = .payNLGiropay
        case "PAY_NL_IDEAL":
            self = .payNLIdeal
        case "PAY_NL_PAYCONIQ":
            self = .payNLPayconiq
        case "PAYMENT_CARD":
            self = .paymentCard
        case "PAYPAL":
            self = .payPal
        default:
            self = .other(rawValue: rawValue)
        }
    }
    
    var rawValue: String {
        switch self {
        case .adyenAlipay:
            return "ADYEN_ALIPAY"
        case .adyenGiropay:
            return "ADYEN_GIROPAY"
        case .adyenMobilePay:
            return "ADYEN_MOBILEPAY"
        case .adyenSofortBanking:
            return "ADYEN_SOFORT_BANKING"
        case .adyenTrustly:
            return "ADYEN_TRUSTLY"
        case .adyenTwint:
            return "ADYEN_TWINT"
        case .adyenVipps:
            return "ADYEN_VIPPS"
        case .apaya:
            return "APAYA"
        case .applePay:
            return "APPLE_PAY"
        case .goCardlessMandate:
            return "GOCARDLESS"
        case .googlePay:
            return "GOOGLE_PAY"
        case .hoolah:
            return "HOOLAH"
        case .klarna:
            return "KLARNA"
        case .mollieIdeal:
            return "MOLLIE_IDEAL"
        case .payNLGiropay:
            return "PAY_NL_GIROPAY"
        case .payNLIdeal:
            return "PAY_NL_IDEAL"
        case .payNLPayconiq:
            return "PAY_NL_PAYCONIQ"
        case .paymentCard:
            return "PAYMENT_CARD"
        case .payPal:
            return "PAYPAL"
        case .other(let rawValue):
            return rawValue
        }
    }
    
    var isEnabled: Bool {
        switch self {
        case .adyenAlipay,
                .adyenGiropay,
                .adyenMobilePay,
                .adyenSofortBanking,
                .adyenTrustly,
                .adyenTwint,
                .adyenVipps,
                .applePay,
                .hoolah,
                .mollieIdeal,
                .payNLGiropay,
                .payNLIdeal,
                .payNLPayconiq:
            guard let flow = Primer.shared.flow else { return false }
            return !flow.internalSessionFlow.vaulted
            
        case .apaya,
                .klarna:
            guard let flow = Primer.shared.flow else { return false }
            return flow.internalSessionFlow.vaulted
            
        case .goCardlessMandate,
                .googlePay:
            return false
            
        case .paymentCard,
                .payPal:
            return true
        
        case .other:
            return true
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
