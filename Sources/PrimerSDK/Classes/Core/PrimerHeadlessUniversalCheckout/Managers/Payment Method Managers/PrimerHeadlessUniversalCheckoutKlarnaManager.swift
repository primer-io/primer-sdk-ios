//
//  KlarnaManager.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 17.02.2024.
//

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
                        userInfo: .errorUserInfoDictionary(
                            additionalInfo: ["message": "Unable to locate a valid payment method configuration"]
                        )
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
