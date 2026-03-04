//
//  TokenizationRequestBody.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerCore
import PrimerFoundation
import PrimerNetworking

public enum TokenType: String, Codable {
    case multiUse = "MULTI_USE"
    case singleUse = "SINGLE_USE"
}

extension Request.Body {

    final class Tokenization: Encodable {

        let paymentInstrument: TokenizationRequestBodyPaymentInstrument
        let tokenType: TokenType?
        let paymentFlow: PrimerSessionIntent?

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case paymentInstrument, tokenType, paymentFlow
        }

        init(paymentInstrument: TokenizationRequestBodyPaymentInstrument) {
            self.paymentInstrument = paymentInstrument
            tokenType = PrimerInternal.shared.intent == .vault ? .multiUse : nil
            paymentFlow = PrimerInternal.shared.intent == .vault ? .vault : nil
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            if let paymentInstrument = paymentInstrument as? ApplePayPaymentInstrument {
                try container.encode(paymentInstrument, forKey: .paymentInstrument)
            } else if let paymentInstrument = paymentInstrument as? CardPaymentInstrument {
                try container.encode(paymentInstrument, forKey: .paymentInstrument)
            } else if let paymentInstrument = paymentInstrument as? KlarnaCustomerTokenPaymentInstrument {
                try container.encode(paymentInstrument, forKey: .paymentInstrument)
            } else if let paymentInstrument = paymentInstrument as? KlarnaAuthorizationPaymentInstrument {
                try container.encode(paymentInstrument, forKey: .paymentInstrument)
            } else if let paymentInstrument = paymentInstrument as? OffSessionPaymentInstrument {
                try container.encode(paymentInstrument, forKey: .paymentInstrument)
            } else if let paymentInstrument = paymentInstrument as? PayPalPaymentInstrument {
                try container.encode(paymentInstrument, forKey: .paymentInstrument)
            } else if let paymentInstrument = paymentInstrument as? CardOffSessionPaymentInstrument {
                try container.encode(paymentInstrument, forKey: .paymentInstrument)
            } else if let paymentInstrument = paymentInstrument as? ACHPaymentInstrument {
                try container.encode(paymentInstrument, forKey: .paymentInstrument)
            } else {
                throw handled(error: InternalError.invalidValue(key: "PaymentInstrument", value: paymentInstrument))
            }

            if let tokenType {
                try container.encode(tokenType, forKey: .tokenType)
            }

            if let paymentFlow {
                try container.encode(paymentFlow, forKey: .paymentFlow)
            }
        }
    }
}
