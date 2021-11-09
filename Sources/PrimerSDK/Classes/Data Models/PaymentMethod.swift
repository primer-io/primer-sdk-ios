#if canImport(UIKit)

protocol PaymentMethodConfigurationOptions: Decodable { }
protocol PaymentInstrument: Encodable {}

public class PaymentMethod: NSObject, Codable {
    
    public enum TokenType: String, Codable {
        case multiUse = "MULTI_USE"
        case singleUse = "SINGLE_USE"
    }
    
    public enum ConfigurationType: Codable, Equatable {
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

    internal struct PaymentCard: PaymentInstrument {
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
    
    internal struct PayPal: PaymentInstrument {
        var paypalOrderId: String?
        var paypalBillingAgreementId: String?
        var shippingAddress: ShippingAddress?
        var externalPayerInfo: PayPalExternalPayerInfo?
        
        struct ConfigurationOptions: PaymentMethodConfigurationOptions {
            let clientId: String
        }
    }
    
    internal struct ApplePay: PaymentInstrument {
        var paymentMethodConfigId: String?
        var token: ApplePayPaymentResponseToken?
        var sourceConfig: ApplePaySourceConfig?
    }
    
    internal struct GoCardless: PaymentInstrument {
        var gocardlessMandateId: String?
    }
    
    internal struct Klarna: PaymentInstrument {
        // Klarna payment session
        var klarnaAuthorizationToken: String?
        // Klarna customer token
        var klarnaCustomerToken: String?
        var sessionData: KlarnaSessionData?
    }
    
    internal struct Apaya: PaymentInstrument {
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
    
    internal struct AsyncPaymentMethod: PaymentInstrument {
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
    
    // MARK: - CONFIGURATION
    
    internal struct Configuration: Decodable {
        let id: String? // Will be nil for cards
        let processorConfigId: String?
        let type: PaymentMethod.ConfigurationType
        let options: PaymentMethodConfigurationOptions?
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
            } else if type == .giropay || type == .sofort || type == .twint || type == .aliPay || type == .trustly {
                return ExternalPaymentMethodTokenizationViewModel(config: self)
            }
            
            return nil
        }
        
        private enum CodingKeys : String, CodingKey {
            case id, options, processorConfigId, type
        }
        
        init(id: String?, options: PaymentMethodConfigurationOptions?, processorConfigId: String?, type: PaymentMethod.ConfigurationType) {
            self.id = id
            self.options = options
            self.processorConfigId = processorConfigId
            self.type = type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String?.self, forKey: .id)
            processorConfigId = try container.decode(String?.self, forKey: .processorConfigId)
            type = try container.decode(PaymentMethod.ConfigurationType.self, forKey: .type)
            
            if let cardOptions = try? container.decode(PaymentMethod.PaymentCard.ConfigurationOptions.self, forKey: .options) {
                options = cardOptions
            } else if let payPalOptions = try? container.decode(PaymentMethod.PayPal.ConfigurationOptions.self, forKey: .options) {
                options = payPalOptions
            } else if let apayaOptions = try? container.decode(PaymentMethod.Apaya.ConfigurationOptions.self, forKey: .options) {
                options = apayaOptions
            } else {
                options = nil
            }
        }
    }
    
    // ---
    
}

#endif

