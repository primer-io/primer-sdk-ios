#if canImport(UIKit)

public enum TokenType: String, Codable {
    case multiUse = "MULTI_USE"
    case singleUse = "SINGLE_USE"
}

class TokenizationRequestBody: Encodable {
    
    let paymentInstrument: TokenizationPaymentInstrument
    let tokenType: TokenType?
    let paymentFlow: PrimerSessionIntent?
    
    private enum CodingKeys : String, CodingKey {
        case paymentInstrument, tokenType, paymentFlow
    }
    
    init(paymentInstrument: TokenizationPaymentInstrument) {
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

struct PayPal {
    struct PayerInfo {
        struct Request: Codable {
            let paymentMethodConfigId: String
            let orderId: String
        }
        
        struct Response: Codable {
            let orderId: String
            let externalPayerInfo: ExternalPayerInfo
        }
    }
}

/**
 Contains information of the payer (if available).
 
 *Values*
 
 `externalPayerId`: ID representing the payer.
 
 `email`: The payer's email.
 
 `firstName`: The payer's firstName.
 
 `lastName`: The payer's lastName.
 
 - Author:
 Primer
 - Version:
 1.2.2
 */

public struct ExternalPayerInfo: Codable {
    public var externalPayerId, email, firstName, lastName: String?
}

#endif
