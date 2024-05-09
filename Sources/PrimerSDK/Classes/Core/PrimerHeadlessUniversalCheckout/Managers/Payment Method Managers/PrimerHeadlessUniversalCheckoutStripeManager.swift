//
//  PrimerHeadlessUniversalCheckoutStripeManager.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

import UIKit

extension PrimerHeadlessUniversalCheckout {
    public class StripeManager: NSObject {
        public var mandateDelegate: StripeAchMandateDelegate?
        
        public func provideStripeAchUserDetailsComponent() throws -> (any StripeAchUserDetailsComponent)? {
            guard let paymentMethod = PrimerAPIConfiguration.paymentMethodConfigs?
                    .first(where: { $0.type == "STRIPE_ACH" })
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
            let tokenizationComponent = StripeAchTokenizationComponent(paymentMethod: paymentMethod)
            return StripeAchHeadlessComponent(tokenizationComponent: tokenizationComponent,
                                              tokenizationViewModel: tokenizationViewModel)
        }
    }
}
