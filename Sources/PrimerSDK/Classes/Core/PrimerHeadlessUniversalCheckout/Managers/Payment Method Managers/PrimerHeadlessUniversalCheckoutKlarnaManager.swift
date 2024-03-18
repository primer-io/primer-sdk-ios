//
//  KlarnaManager.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 17.02.2024.
//

#if canImport(PrimerKlarnaSDK)
import UIKit
import PrimerKlarnaSDK

extension PrimerHeadlessUniversalCheckout {
    public class KlarnaManager: NSObject {
        public func provideKlarnaComponent(with intent: PrimerSessionIntent) throws -> (any KlarnaComponent)? {
            guard let paymentMethod = PrimerAPIConfiguration.paymentMethodConfigs?.first(where: { $0.type == "KLARNA" }) 
            else {
                let err = PrimerError.generic(message: "Unable to locate a valid payment method configuration.",
                                              userInfo: ["file": #file,
                                                         "class": "\(Self.self)",
                                                         "function": #function,
                                                         "line": "\(#line)"],
                                              diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if (intent == .vault && !paymentMethod.isVaultingEnabled) ||
                (intent == .checkout && !paymentMethod.isCheckoutEnabled) {
                let err = PrimerError.unsupportedIntent(intent: intent,
                                                        userInfo: ["file": #file,
                                                                   "class": "\(Self.self)",
                                                                   "function": #function,
                                                                   "line": "\(#line)"],
                                                        diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            PrimerInternal.shared.intent = intent
            let tokenizationComponent = KlarnaTokenizationComponent(paymentMethod: paymentMethod)
            return PrimerHeadlessKlarnaComponent(tokenizationComponent: tokenizationComponent)
        }
    }
}
#endif
