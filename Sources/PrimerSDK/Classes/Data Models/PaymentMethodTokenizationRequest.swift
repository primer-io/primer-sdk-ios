#if canImport(UIKit)

protocol TokenizationRequest: Encodable {}

struct PaymentMethodTokenizationRequest: TokenizationRequest {
    
    let paymentInstrument: PaymentInstrumentProtocol
    let tokenType: TokenType?
    let paymentFlow: PaymentFlow?
    let customerId: String?
    
    private enum CodingKeys : String, CodingKey {
        case paymentInstrument, tokenType, paymentFlow, customerId
    }

    init(paymentInstrument: PaymentInstrumentProtocol) {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        self.paymentInstrument = paymentInstrument
        self.tokenType = Primer.shared.flow.internalSessionFlow.vaulted ? .multiUse : .singleUse
        self.paymentFlow = Primer.shared.flow.internalSessionFlow.vaulted ? .vault : nil
        self.customerId = Primer.shared.flow.internalSessionFlow.vaulted ? settings.customerId : nil
    }
    
    init(paymentInstrument: PaymentInstrumentProtocol, paymentFlow: PaymentFlow, customerId: String?) {
        self.paymentInstrument = paymentInstrument
        self.paymentFlow = paymentFlow
        self.tokenType = (paymentFlow == .vault) ? .multiUse : .singleUse
        self.customerId = customerId
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let paymentCard = paymentInstrument as? PaymentMethod.PaymentCard {
            try container.encode(paymentCard, forKey: .paymentInstrument)
        } else if let payPal = paymentInstrument as? PaymentMethod.PayPal {
            try container.encode(payPal, forKey: .paymentInstrument)
        } else if let applePay = paymentInstrument as? PaymentMethod.ApplePay {
            try container.encode(applePay, forKey: .paymentInstrument)
        } else if let goCardless = paymentInstrument as? PaymentMethod.GoCardless {
            try container.encode(goCardless, forKey: .paymentInstrument)
        } else if let klarna = paymentInstrument as? PaymentMethod.Klarna {
            try container.encode(klarna, forKey: .paymentInstrument)
        } else if let apaya = paymentInstrument as? PaymentMethod.Apaya {
            try container.encode(apaya, forKey: .paymentInstrument)
        } else if let asyncPaymentMethod = paymentInstrument as? PaymentMethod.AsyncPaymentMethod {
            try container.encode(asyncPaymentMethod, forKey: .paymentInstrument)
        } else {
            throw PrimerError.generic
        }

        try? container.encode(tokenType, forKey: .tokenType)
        try? container.encode(paymentFlow, forKey: .paymentFlow)
        try? container.encode(customerId, forKey: .customerId)
    }

}

protocol PaymentMethodConfigurationOptions: Codable { }
extension PaymentMethodConfigurationOptions { }

protocol PaymentInstrumentProtocol: Encodable {}
public struct PaymentMethod {
    
    public enum ConfigurationType: Codable, Equatable /*: String, Codable*/ {
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
                guard let flow = Primer.shared.flow else { return false }
                return flow.internalSessionFlow.vaulted
            case .aliPay,
                    .applePay,
                    .giropay,
                    .hoolah,
                    .payNLIdeal,
                    .sofort,
                    .trustly,
                    .twint:
                guard let flow = Primer.shared.flow else { return false }
                return !flow.internalSessionFlow.vaulted
            case .other:
                return true
            }
        }
        
        public init(from decoder: Decoder) throws {
            let rawValue: String = try decoder.singleValueContainer().decode(String.self)
            self = PaymentMethod.ConfigurationType(rawValue: rawValue)
        }
    }

    struct PaymentCard: PaymentInstrumentProtocol {
        var number: String
        var cvv: String
        var expirationMonth: String
        var expirationYear: String
        var cardholderName: String?
        
        struct ConfigurationOptions: PaymentMethodConfigurationOptions {
            let threeDSecureEnabled: Bool
            let threeDSecureToken: String?
            let threeDSecureInitUrl: String?
            let threeDSecureProvider: String
            let processorConfigId: String?
        }
    }
    
    struct PayPal: PaymentInstrumentProtocol {
        var paypalOrderId: String?
        var paypalBillingAgreementId: String?
        var shippingAddress: ShippingAddress?
        var externalPayerInfo: PayPalExternalPayerInfo?
        
        struct ConfigurationOptions: PaymentMethodConfigurationOptions {
            let clientId: String
        }
    }
    
    struct ApplePay: PaymentInstrumentProtocol {
        var paymentMethodConfigId: String?
        var token: ApplePayPaymentResponseToken?
        var sourceConfig: ApplePaySourceConfig?
    }
    
    struct GoCardless: PaymentInstrumentProtocol {
        var gocardlessMandateId: String?
    }
    
    struct Klarna: PaymentInstrumentProtocol {
        // Klarna payment session
        var klarnaAuthorizationToken: String?
        // Klarna customer token
        var klarnaCustomerToken: String?
        var sessionData: KlarnaSessionData?
    }
    
    struct Apaya: PaymentInstrumentProtocol {
        var mx: String?
        var mnc: String?
        var mcc: String?
        var hashedIdentifier: String?
        var productId: String?
        var currencyCode: String?
        
        struct ConfigurationOptions: PaymentMethodConfigurationOptions {
            let merchantAccountId: String
        }
    }
    
    struct AsyncPaymentMethod: PaymentInstrumentProtocol {
        let paymentMethodType: PaymentMethod.ConfigurationType
        let paymentMethodConfigId: String
        let type: String = "OFF_SESSION_PAYMENT"
        let sessionInfo: SessionInfo?
        
        private enum CodingKeys : String, CodingKey {
            case type, paymentMethodType, paymentMethodConfigId, sessionInfo
        }
        
        init(
            paymentMethodType: PaymentMethod.ConfigurationType,
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
        
        struct ConfigurationOptions: PaymentMethodConfigurationOptions {

        }
    }
    
}

public enum TokenType: String, Codable {
    case multiUse = "MULTI_USE"
    case singleUse = "SINGLE_USE"
}

public enum PaymentFlow: String, Encodable {
    case vault = "VAULT"
    case checkout = "CHECKOUT"
}

struct ApplePaySourceConfig: Codable {
    let source: String
    let merchantId: String
}

#endif
