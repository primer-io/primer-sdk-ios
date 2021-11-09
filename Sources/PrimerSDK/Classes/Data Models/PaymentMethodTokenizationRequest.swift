#if canImport(UIKit)

protocol TokenizationRequest: Encodable {}

struct PaymentMethodTokenizationRequest: TokenizationRequest {
    
    let paymentInstrument: PaymentInstrumentProtocol
    let tokenType: PaymentMethod.TokenType?
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

public enum PaymentFlow: String, Encodable {
    case vault = "VAULT"
    case checkout = "CHECKOUT"
}

struct ApplePaySourceConfig: Codable {
    let source: String
    let merchantId: String
}

#endif
