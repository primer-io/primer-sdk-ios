//
//  PrimerHeadlessUniversalCheckoutPaymentMethod.swift
//  PrimerSDK
//
//  Created by Evangelos on 27/9/22.
//

#if canImport(UIKit)

import Foundation

public class PrimerHeadlessUniversalCheckoutPaymentMethod {
    
    static var availablePaymentMethods: [PrimerHeadlessUniversalCheckoutPaymentMethod] {
        let availablePaymentMethods = PrimerAPIConfiguration.paymentMethodConfigs?
            .compactMap({ $0.type })
            .compactMap({ PrimerHeadlessUniversalCheckoutPaymentMethod(paymentMethodType: $0) })
        return availablePaymentMethods ?? []
    }
    
    public var paymentMethodType: String
    public var supportedPrimerSessionIntents: [PrimerSessionIntent] = []
    public var paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory]
    public var requiredInputDataClass: PrimerRawData.Type?
    
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
    }
}

#endif
