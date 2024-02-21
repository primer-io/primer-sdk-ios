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
        
        // MARK: - Klarna Component
        
        /// Component responsible for managing session creation stages of the Klarna payment session.
        var klarnaComponent: KlarnaComponent?
        
        // MARK: - Init
        public init(paymentMethodType: String, intent: PrimerSessionIntent) {
            super.init()
            
            guard let paymentMethod = PrimerAPIConfiguration.paymentMethodConfigs?.first(where: { $0.type == paymentMethodType }) else {
                let err = PrimerError.generic(message: "Unable to locate a valid payment method component",
                                              userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                                              diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                return
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
                return
            }
            
            PrimerInternal.shared.intent = intent
            
            let tokenizationComponent = KlarnaTokenizationComponent(paymentMethod: paymentMethod)
            self.klarnaComponent = KlarnaComponent(tokenizationComponent: tokenizationComponent)
        }
        
        public func provideKlarnaComponent() -> KlarnaComponent? {
            return klarnaComponent
        }
    }
    
}
#endif

