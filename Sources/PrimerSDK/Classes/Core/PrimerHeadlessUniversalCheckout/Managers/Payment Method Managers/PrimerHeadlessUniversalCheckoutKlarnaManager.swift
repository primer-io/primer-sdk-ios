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
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: "KLARNA",
                                                               userInfo: .errorUserInfoDictionary(additionalInfo: [
                                                                "message": "Unable to locate a valid payment method configuration"
                                                               ]),
                                                               diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            if (intent == .vault && !paymentMethod.isVaultingEnabled) ||
                (intent == .checkout && !paymentMethod.isCheckoutEnabled) {
                let err = PrimerError.unsupportedIntent(intent: intent,
                                                        userInfo: .errorUserInfoDictionary(),
                                                        diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
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
