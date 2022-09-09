#if canImport(UIKit)

public enum TokenType: String, Codable {
    case multiUse = "MULTI_USE"
    case singleUse = "SINGLE_USE"
}

extension Request.Body {

    class Tokenization: Encodable {
        
        let paymentInstrument: TokenizationRequestBodyPaymentInstrument
        let tokenType: TokenType?
        let paymentFlow: PrimerSessionIntent?
        
        private enum CodingKeys : String, CodingKey {
            case paymentInstrument, tokenType, paymentFlow
        }
        
        init(paymentInstrument: TokenizationRequestBodyPaymentInstrument) {
            self.paymentInstrument = paymentInstrument
            self.tokenType = Primer.shared.intent == .vault ? .multiUse : nil
            self.paymentFlow = Primer.shared.intent == .vault ? .vault : nil
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            if let paymentInstrument = self.paymentInstrument as? ApayaPaymentInstrument {
                try container.encode(paymentInstrument, forKey: .paymentInstrument)
            } else if let paymentInstrument = self.paymentInstrument as? ApplePayPaymentInstrument {
                try container.encode(paymentInstrument, forKey: .paymentInstrument)
            } else if let paymentInstrument = self.paymentInstrument as? CardPaymentInstrument {
                try container.encode(paymentInstrument, forKey: .paymentInstrument)
            } else if let paymentInstrument = self.paymentInstrument as? KlarnaCustomerTokenPaymentInstrument {
                try container.encode(paymentInstrument, forKey: .paymentInstrument)
            } else if let paymentInstrument = self.paymentInstrument as? KlarnaPaymentSessionPaymentInstrument {
                try container.encode(paymentInstrument, forKey: .paymentInstrument)
            } else if let paymentInstrument = self.paymentInstrument as? OffSessionPaymentInstrument {
                try container.encode(paymentInstrument, forKey: .paymentInstrument)
            }  else if let paymentInstrument = self.paymentInstrument as? PayPalPaymentInstrument {
                try container.encode(paymentInstrument, forKey: .paymentInstrument)
            } else {
                let err = InternalError.invalidValue(key: "PaymentInstrument", value: self.paymentInstrument, userInfo: nil, diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if let tokenType = tokenType {
                try container.encode(tokenType, forKey: .tokenType)
            }
            
            if let paymentFlow = paymentFlow {
                try container.encode(paymentFlow, forKey: .paymentFlow)
            }
        }
    }
}

#endif
