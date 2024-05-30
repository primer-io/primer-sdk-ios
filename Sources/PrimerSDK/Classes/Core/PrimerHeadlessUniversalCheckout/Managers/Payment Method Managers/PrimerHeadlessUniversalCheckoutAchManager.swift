//
//  PrimerHeadlessUniversalCheckoutAchManager.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

import UIKit

extension PrimerHeadlessUniversalCheckout {
    public class AchManager: NSObject {
        public var mandateDelegate: ACHMandateDelegate?
        
        public func provide<ACHComponent>(paymentMethodType: String) throws -> ACHComponent?
        where PrimerCollectableData: Any, PrimerHeadlessStep: Any {
            try provideStripeAchUserDetailsComponent(paymentMethodType: paymentMethodType) as? ACHComponent
        }
        
        public func provideStripeAchUserDetailsComponent(paymentMethodType: String) throws -> (any StripeAchUserDetailsComponent)? {
            guard let paymentMethod = PrimerAPIConfiguration.paymentMethodConfigs?
                .first(where: { $0.type == paymentMethodType })
            else {
                
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType,
                                                               userInfo: .errorUserInfoDictionary(additionalInfo: [
                                                                "message": "Unable to locate a valid payment method configuration"
                                                               ]),
                                                               diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            guard let tokenizationViewModel = paymentMethod.tokenizationViewModel as? StripeAchTokenizationViewModel else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType,
                                                               userInfo: .errorUserInfoDictionary(additionalInfo: [
                                                                "message": "Unable to locate a valid payment method view model."
                                                               ]),
                                                               diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            mandateDelegate = tokenizationViewModel
            let tokenizationService = ACHTokenizationService(paymentMethod: paymentMethod)
            return StripeAchHeadlessComponent(tokenizationService: tokenizationService,
                                              tokenizationViewModel: tokenizationViewModel)
        }
    }
}
