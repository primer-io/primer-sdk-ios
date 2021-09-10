#if canImport(UIKit)

struct PaymentMethodRequest: Encodable {
    
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
    
    init(paymentMethodDetails: PaymentMethodDetailsProtocol, state: AppStateProtocol) {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        self.paymentInstrument = paymentMethodDetails
        self.tokenType = Primer.shared.flow.internalSessionFlow.vaulted ? .multiUse : .singleUse
        self.paymentFlow = .vault // Primer.shared.flow.internalSessionFlow.vaulted ? .vault : .nil
        self.customerId = Primer.shared.flow.internalSessionFlow.vaulted ? settings.customerId : nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let paymentInstrument = paymentInstrument as? PaymentMethodOptions.Apaya.Details {
            try container.encode(paymentInstrument, forKey: .paymentInstrument)
        } else if let paymentInstrument = paymentInstrument as? PaymentMethodOptions.ApplePay.Details {
            try container.encode(paymentInstrument, forKey: .paymentInstrument)
        } else if let paymentInstrument = paymentInstrument as? PaymentMethodOptions.Card.Details {
            try container.encode(paymentInstrument, forKey: .paymentInstrument)
        } else if let paymentInstrument = paymentInstrument as? PaymentMethodOptions.GoCardless.Details {
            try container.encode(paymentInstrument, forKey: .paymentInstrument)
        } else if let paymentInstrument = paymentInstrument as? PaymentMethodOptions.Klarna.Details {
            try container.encode(paymentInstrument, forKey: .paymentInstrument)
        } else if let paymentInstrument = paymentInstrument as? PaymentMethodOptions.PayPal.Details {
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
