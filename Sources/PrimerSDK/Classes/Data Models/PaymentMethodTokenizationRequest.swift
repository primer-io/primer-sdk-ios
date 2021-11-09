#if canImport(UIKit)

protocol TokenizationRequest: Encodable {}

struct PaymentMethodTokenizationRequest: TokenizationRequest {
    
    let paymentInstrument: PaymentInstrumentProtocol
    let tokenType: TokenType
    let paymentFlow: PaymentFlow?
    let customerId: String?
    
    private enum CodingKeys : String, CodingKey {
        case paymentInstrument, tokenType, paymentFlow, customerId
    }

    init(paymentInstrument: PaymentInstrumentProtocol, state: AppStateProtocol?) {
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
        } else {
            throw PrimerError.generic
        }
//        try container.encode(paymentInstrument, forKey: .paymentInstrument)
        try container.encode(tokenType, forKey: .tokenType)
        try? container.encode(paymentFlow, forKey: .paymentFlow)
        try? container.encode(customerId, forKey: .customerId)
    }

}

struct AsyncPaymentMethodTokenizationRequest: TokenizationRequest {
    let paymentInstrument: PaymentMethod.AsyncPaymentMethod
}

protocol PaymentMethodConfigurationOptions: Codable { }
extension PaymentMethodConfigurationOptions { }

protocol PaymentInstrumentProtocol: Encodable {}
// feels like we could polymorph this with a protocol, or at least restrict construcions with a specific factory method for each payment instrument.
struct PaymentMethod: Encodable {

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
    
    struct AsyncPaymentMethod: PaymentMethodConfigurationOptions {
        
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
