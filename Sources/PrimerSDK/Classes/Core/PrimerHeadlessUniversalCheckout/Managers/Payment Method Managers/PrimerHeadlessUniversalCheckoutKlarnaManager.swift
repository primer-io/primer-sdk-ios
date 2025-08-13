//
//  PrimerHeadlessUniversalCheckoutKlarnaManager.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit
#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK
#endif

extension PrimerHeadlessUniversalCheckout {
    public final class KlarnaManager: NSObject {
        public func provideKlarnaComponent(with intent: PrimerSessionIntent) throws -> (any KlarnaComponent)? {
            #if canImport(PrimerKlarnaSDK)
            guard let paymentMethod = PrimerAPIConfiguration.paymentMethodConfigs?
                    .first(where: { $0.type == "KLARNA" })
            else {
                throw handled(
                    primerError: .unsupportedPaymentMethod(
                        paymentMethodType: "KLARNA",
                        reason: "Unable to locate a valid payment method configuration"
                    )
                )
            }

            if (intent == .vault && !paymentMethod.isVaultingEnabled) ||
                (intent == .checkout && !paymentMethod.isCheckoutEnabled) {
                throw handled(primerError: .unsupportedIntent(intent: intent))
            }
            PrimerInternal.shared.intent = intent
            let tokenizationComponent = KlarnaTokenizationComponent(paymentMethod: paymentMethod)
            return PrimerHeadlessKlarnaComponent(tokenizationComponent: tokenizationComponent)
            #else
            return nil
            #endif
        }
    }
}
