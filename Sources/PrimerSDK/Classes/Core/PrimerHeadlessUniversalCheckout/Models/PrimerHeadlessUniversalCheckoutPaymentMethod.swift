//
//  PrimerHeadlessUniversalCheckoutPaymentMethod.swift
//  PrimerSDK
//
//  Created by Evangelos on 27/9/22.
//

#if canImport(UIKit)

import Foundation

extension PrimerHeadlessUniversalCheckout {
    
    public class PaymentMethod: NSObject {
        
        static var availablePaymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod] {
            let availablePaymentMethods = PrimerAPIConfiguration.paymentMethodConfigs?
                .compactMap({ $0.type })
                .compactMap({ PrimerHeadlessUniversalCheckout.PaymentMethod(paymentMethodType: $0) })
            return availablePaymentMethods ?? []
        }
        
        public private(set) var paymentMethodType: String
        public private(set) var supportedPrimerSessionIntents: [PrimerSessionIntent] = []
        public private(set) var paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory]
        public private(set) var requiredInputDataClass: PrimerRawData.Type?
        
        init?(paymentMethodType: String) {
            guard let paymentMethod = PrimerAPIConfiguration.paymentMethodConfigs?.first(where: { $0.type == paymentMethodType }) else {
                return nil
            }
            
            self.paymentMethodType = paymentMethodType
                    
            if paymentMethod.isCheckoutEnabled {
                supportedPrimerSessionIntents.append(.checkout)
            }
            
            if paymentMethod.isVaultingEnabled {
                supportedPrimerSessionIntents.append(.vault)
            }
            
            guard let paymentMethodManagerCategories = paymentMethod.paymentMethodManagerCategories else {
                return nil
            }
            
            self.paymentMethodManagerCategories = paymentMethodManagerCategories
            
            if PrimerPaymentMethodType.paymentCard.rawValue == paymentMethodType {
                requiredInputDataClass = PrimerCardData.self
            }
            
            super.init()
        }
    }
}

#endif
