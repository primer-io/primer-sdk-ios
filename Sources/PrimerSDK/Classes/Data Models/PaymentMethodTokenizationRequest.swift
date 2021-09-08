#if canImport(UIKit)

struct PaymentInstrumentizationRequest: Encodable {
    
    let paymentInstrument: PaymentMethodDetailsProtocol
    let tokenType: TokenType
    let paymentFlow: PaymentFlow
    let customerId: String?
    
    enum CodingKeys: String, CodingKey {
        case paymentInstrument
        case tokenType
        case paymentFlow
        case customerId
    }
    
    init(paymentInstrument: PaymentMethodDetailsProtocol, state: AppStateProtocol) {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        self.paymentInstrument = paymentInstrument
        self.tokenType = Primer.shared.flow.internalSessionFlow.vaulted ? .multiUse : .singleUse
        self.paymentFlow = .vault // Primer.shared.flow.internalSessionFlow.vaulted ? .vault : .nil
        self.customerId = Primer.shared.flow.internalSessionFlow.vaulted ? settings.customerId : nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let paymentInstrument = paymentInstrument as? PaymentMethod.Apaya.Details {
            try container.encode(paymentInstrument, forKey: .paymentInstrument)
        } else if let paymentInstrument = paymentInstrument as? PaymentMethod.ApplePay.Details {
            try container.encode(paymentInstrument, forKey: .paymentInstrument)
        } else if let paymentInstrument = paymentInstrument as? PaymentMethod.Card.Details {
            try container.encode(paymentInstrument, forKey: .paymentInstrument)
        } else if let paymentInstrument = paymentInstrument as? PaymentMethod.GoCardless.Details {
            try container.encode(paymentInstrument, forKey: .paymentInstrument)
        } else if let paymentInstrument = paymentInstrument as? PaymentMethod.Klarna.Details {
            try container.encode(paymentInstrument, forKey: .paymentInstrument)
        } else if let paymentInstrument = paymentInstrument as? PaymentMethod.PayPal.Details {
            try container.encode(paymentInstrument, forKey: .paymentInstrument)
        } else {
            assert(true, "paymentInstrument is of no known type and can't be encoded.")
        }
        
//        if let customerId = customerId {
//            try container.encode(customerId, forKey: .customerId)
//        }
        
        try container.encode(tokenType, forKey: .tokenType)
        
        if paymentFlow == .vault && tokenType == .multiUse {
            try container.encode(paymentFlow, forKey: .paymentFlow)
        }
    }
}

enum TokenType: String, Encodable {
    case multiUse = "MULTI_USE"
    case singleUse = "SINGLE_USE"
}

enum PaymentFlow: String, Encodable {
    case vault = "VAULT"
}

#endif
