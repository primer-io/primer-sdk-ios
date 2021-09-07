#if canImport(UIKit)

struct PaymentMethodTokenizationRequest: Encodable {
    
    let paymentInstrument: PaymentMethodDetailsProtocol
    let tokenType: TokenType
    let paymentFlow: PaymentFlow?
    let customerId: String?

    init(paymentInstrument: PaymentMethodDetailsProtocol, state: AppStateProtocol) {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        self.paymentInstrument = paymentInstrument
        self.tokenType = Primer.shared.flow.internalSessionFlow.vaulted ? .multiUse : .singleUse
        self.paymentFlow = Primer.shared.flow.internalSessionFlow.vaulted ? .vault : nil
        self.customerId = Primer.shared.flow.internalSessionFlow.vaulted ? settings.customerId : nil
    }

}

// feels like we could polymorph this with a protocol, or at least restrict construcions with a specific factory method for each payment instrument.


enum TokenType: String, Encodable {
    case multiUse = "MULTI_USE"
    case singleUse = "SINGLE_USE"
}

enum PaymentFlow: String, Encodable {
    case vault = "VAULT"
}

#endif
