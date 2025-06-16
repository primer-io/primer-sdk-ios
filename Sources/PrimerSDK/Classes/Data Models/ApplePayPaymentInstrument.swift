import PassKit.PKPayment

struct ApplePayPaymentInstrument: TokenizationRequestBodyPaymentInstrument {
    let paymentMethodConfigId: String
    let sourceConfig: ApplePayPaymentInstrument.SourceConfig
    let token: ApplePayPaymentInstrument.PaymentResponseToken

    struct SourceConfig: Codable {
        let source: String
        let merchantId: String
    }

    struct PaymentResponseToken: Codable {
        let paymentMethod: ApplePayPaymentResponsePaymentMethod
        let transactionIdentifier: String
        let paymentData: ApplePayPaymentResponseTokenPaymentData
    }
}

extension ApplePayPaymentInstrument.PaymentResponseToken {
    init(
        token: PKPaymentToken,
        paymentData: ApplePayPaymentResponseTokenPaymentData
    ) {
        paymentMethod = ApplePayPaymentResponsePaymentMethod(
            displayName: token.paymentMethod.displayName,
            network: token.paymentMethod.network?.rawValue,
            type: token.paymentMethod.type.primerValue
        )
        transactionIdentifier = token.transactionIdentifier
        self.paymentData = paymentData
    }
}

private extension PKPaymentMethodType {
    var primerValue: String? {
        switch self {
        case .credit, .debit, .prepaid: String(describing: self)
        default: nil
        }
    }
}
