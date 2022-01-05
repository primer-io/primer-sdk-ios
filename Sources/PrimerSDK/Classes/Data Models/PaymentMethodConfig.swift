#if canImport(UIKit)

struct PrimerConfiguration: Codable {
    
    static var paymentMethodConfigs: [PaymentMethodConfig]? {
        if Primer.shared.flow == nil { return nil }
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state
            .primerConfiguration?
            .paymentMethods
    }
    
    static var paymentMethodConfigViewModels: [PaymentMethodTokenizationViewModelProtocol] {
        var viewModels = PrimerConfiguration.paymentMethodConfigs?
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
    let clientSession: ClientSession?
    let paymentMethods: [PaymentMethodConfig]?
    let checkoutModules: [CheckoutModule]?
    let keys: ThreeDS.Keys?
    
    var isSetByClientSession: Bool {
        return clientSession != nil
    }
    
    var requirePostalCode: Bool {
        checkoutModules?
            .first { $0.type == "BILLING_ADDRESS" }?
            .options?["postalCode"] ?? false
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.coreUrl = (try? container.decode(String?.self, forKey: .coreUrl)) ?? nil
        self.pciUrl = (try? container.decode(String?.self, forKey: .pciUrl)) ?? nil
        self.clientSession = (try? container.decode(ClientSession?.self, forKey: .clientSession)) ?? nil
        let throwables = try container.decode([Throwable<PaymentMethodConfig>].self, forKey: .paymentMethods)
        self.paymentMethods = throwables.compactMap({ $0.value })
        let moduleThrowables = try container.decode([Throwable<CheckoutModule>].self, forKey: .checkoutModules)
        self.checkoutModules = moduleThrowables.compactMap({ $0.value })
        self.keys = (try? container.decode(ThreeDS.Keys?.self, forKey: .keys)) ?? nil
        
        if let options = clientSession?.paymentMethod?.options, !options.isEmpty {
            for paymentMethodOption in options {
                if let type = paymentMethodOption["type"] as? String {
                    if type == PaymentMethodConfigType.paymentCard.rawValue,
                        let networks = paymentMethodOption["networks"] as? [[String: Any]],
                       !networks.isEmpty
                    {
                        for network in networks {
                            guard let type = network["type"] as? String,
                            let surcharge = network["surcharge"] as? Int
                            else { continue }
                            
                        }
                    } else if let surcharge = paymentMethodOption["surcharge"] as? Int,
                              let paymentMethod = self.paymentMethods?.filter({ $0.type.rawValue == type }).first
                    {
                        paymentMethod.hasUnknownSurcharge = false
                        paymentMethod.surcharge = surcharge
                    }
                }
            }
        }
        
        if let paymentMethod = self.paymentMethods?.filter({ $0.type == PaymentMethodConfigType.paymentCard }).first {
            paymentMethod.hasUnknownSurcharge = true
            paymentMethod.surcharge = nil
        }
    }
    
    init(
        coreUrl: String?,
        pciUrl: String?,
        clientSession: ClientSession?,
        paymentMethods: [PaymentMethodConfig]?,
        checkoutModules: [CheckoutModule]?,
        keys: ThreeDS.Keys?
    ) {
        self.coreUrl = coreUrl
        self.pciUrl = pciUrl
        self.clientSession = clientSession
        self.paymentMethods = paymentMethods
        self.checkoutModules = checkoutModules
        self.keys = keys
    }
    
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

class PaymentMethodConfig: Codable {
    
    let id: String? // Will be nil for cards
    let processorConfigId: String?
    let type: PaymentMethodConfigType
    let options: PaymentMethodOptions?
    var surcharge: Int?
    var hasUnknownSurcharge: Bool = false
    var tokenizationViewModel: PaymentMethodTokenizationViewModelProtocol? {
        let asyncPaymentMethodTypes: [PaymentMethodConfigType] = [
            .adyenMobilePay,
            .adyenVipps,
            .adyenAlipay,
            .adyenGiropay,
            .atome,
            .buckarooBancontact,
            .buckarooEps,
            .buckarooGiropay,
            .buckarooIdeal,
            .buckarooSofort,
            .mollieBankcontact,
            .mollieIdeal,
            .payNLBancontact,
            .payNLGiropay,
            .payNLPayconiq,
            .adyenSofort,
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
        } else if type == .adyenDotPay || type == .adyenIDeal {
            return BankSelectorTokenizationViewModel(config: self)
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
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(PaymentMethodConfigType.self, forKey: .type)
        id = (try? container.decode(String?.self, forKey: .id)) ?? nil
        processorConfigId = (try? container.decode(String?.self, forKey: .processorConfigId)) ?? nil
        
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
    case adyenDotPay
    case adyenGiropay
    case adyenIDeal
    case adyenMobilePay
    case adyenSofort
    case adyenTrustly
    case adyenTwint
    case adyenVipps
    case apaya
    case applePay
    case atome
    case buckarooBancontact
    case buckarooEps
    case buckarooGiropay
    case buckarooIdeal
    case buckarooSofort
    case goCardlessMandate
    case googlePay
    case hoolah
    case klarna
    case mollieBankcontact
    case mollieIdeal
    case payNLBancontact
    case payNLGiropay
    case payNLIdeal
    case payNLPayconiq
    case paymentCard
    case payPal
    case other(rawValue: String)
    
    // swiftlint:disable cyclomatic_complexity
    init(rawValue: String) {
        switch rawValue {
        case "ADYEN_ALIPAY":
            self = .adyenAlipay
        case "ADYEN_DOTPAY":
            self = .adyenDotPay
        case "ADYEN_GIROPAY":
            self = .adyenGiropay
        case "ADYEN_IDEAL":
            self = .adyenIDeal
        case "ADYEN_MOBILEPAY":
            self = .adyenMobilePay
        case "ADYEN_SOFORT":
            self = .adyenSofort
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
        case "ATOME":
            self = .atome
        case "BUCKAROO_BANCONTACT":
            self = .buckarooBancontact
        case "BUCKAROO_EPS":
            self = .buckarooEps
        case "BUCKAROO_GIROPAY":
            self = .buckarooGiropay
        case "BUCKAROO_IDEAL":
            self = .buckarooIdeal
        case "BUCKAROO_SOFORT":
            self = .buckarooSofort
        case "GOCARDLESS":
            self = .goCardlessMandate
        case "GOOGLE_PAY":
            self = .googlePay
        case "HOOLAH":
            self = .hoolah
        case "KLARNA":
            self = .klarna
        case "MOLLIE_BANCONTACT":
            self = .mollieBankcontact
        case "MOLLIE_IDEAL":
            self = .mollieIdeal
        case "PAY_NL_BANCONTACT":
            self = .payNLBancontact
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
        case .adyenDotPay:
            return "ADYEN_DOTPAY"
        case .adyenGiropay:
            return "ADYEN_GIROPAY"
        case .adyenIDeal:
            return "ADYEN_IDEAL"
        case .adyenMobilePay:
            return "ADYEN_MOBILEPAY"
        case .adyenSofort:
            return "ADYEN_SOFORT"
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
        case .atome:
            return "ATOME"
        case .buckarooBancontact:
            return "BUCKAROO_BANCONTACT"
        case .buckarooEps:
            return "BUCKAROO_EPS"
        case .buckarooGiropay:
            return "BUCKAROO_GIROPAY"
        case .buckarooIdeal:
            return "BUCKAROO_IDEAL"
        case .buckarooSofort:
            return "BUCKAROO_SOFORT"
        case .goCardlessMandate:
            return "GOCARDLESS"
        case .googlePay:
            return "GOOGLE_PAY"
        case .hoolah:
            return "HOOLAH"
        case .klarna:
            return "KLARNA"
        case .mollieBankcontact:
            return "MOLLIE_BANCONTACT"
        case .mollieIdeal:
            return "MOLLIE_IDEAL"
        case .payNLBancontact:
            return "PAY_NL_BANCONTACT"
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
                .adyenDotPay,
                .adyenGiropay,
                .adyenIDeal,
                .adyenMobilePay,
                .adyenSofort,
                .adyenTrustly,
                .adyenTwint,
                .adyenVipps,
                .applePay,
                .atome,
                .buckarooBancontact,
                .buckarooEps,
                .buckarooGiropay,
                .buckarooIdeal,
                .buckarooSofort,
                .hoolah,
                .mollieBankcontact,
                .mollieIdeal,
                .payNLBancontact,
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
    // swiftlint:enable cyclomatic_complexity
    
    private enum CodingKeys: String, CodingKey {
        case adyenAlipay
        case adyenDotPay
        case adyenGiropay
        case adyenIDeal
        case adyenMobilePay
        case adyenSofort
        case adyenTrustly
        case adyenTwint
        case adyenVipps
        case apaya
        case applePay
        case atome
        case buckarooBancontact
        case buckarooEps
        case buckarooGiropay
        case buckarooIdeal
        case buckarooSofort
        case goCardlessMandate
        case googlePay
        case hoolah
        case klarna
        case mollieBankcontact
        case mollieIdeal
        case payNLBancontact
        case payNLGiropay
        case payNLIdeal
        case payNLPayconiq
        case paymentCard
        case payPal
        case other
    }
    
    public init(from decoder: Decoder) throws {
        let rawValue: String = try decoder.singleValueContainer().decode(String.self)
        self = PaymentMethodConfigType(rawValue: rawValue)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.rawValue, forKey: CodingKeys(rawValue: "type")!)
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
