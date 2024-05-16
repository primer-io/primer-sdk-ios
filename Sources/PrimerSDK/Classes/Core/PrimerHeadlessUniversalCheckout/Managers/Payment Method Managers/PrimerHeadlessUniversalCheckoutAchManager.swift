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
        
        public func provide<MainComponent>(paymentMethodType: String) throws -> MainComponent?
        where PrimerCollectableData: Any, PrimerHeadlessStep: Any {
            try provideStripeAchUserDetailsComponent(paymentMethodType: paymentMethodType) as? MainComponent
        }
        
        public func provideStripeAchUserDetailsComponent(paymentMethodType: String) throws -> (any StripeAchUserDetailsComponent)? {
            guard let paymentMethod = PrimerAPIConfiguration.paymentMethodConfigs?
                    .first(where: { $0.type == paymentMethodType })
            else {
                let err = PrimerError.generic(message: "Unable to locate a valid payment method configuration.",
                                              userInfo: .errorUserInfoDictionary(),
                                              diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            guard let tokenizationViewModel = paymentMethod.tokenizationViewModel as? StripeTokenizationViewModel else {
                let err = PrimerError.generic(message: "Unable to locate a valid payment method view model.",
                                              userInfo: .errorUserInfoDictionary(),
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
