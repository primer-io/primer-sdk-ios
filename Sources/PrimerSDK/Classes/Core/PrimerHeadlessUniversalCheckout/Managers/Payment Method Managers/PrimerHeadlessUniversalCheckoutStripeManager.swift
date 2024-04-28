//
//  PrimerHeadlessUniversalCheckoutStripeManager.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

import UIKit

extension PrimerHeadlessUniversalCheckout {
    public class StripeManager: NSObject {
        public func provideStripeAchUserDetailsComponent() throws -> (any KlarnaComponent)? {
            guard let paymentMethod = PrimerAPIConfiguration.paymentMethodConfigs?
                    .first(where: { $0.type == "STRIPE_ACH" })
            else {
                let err = PrimerError.generic(message: "Unable to locate a valid payment method configuration.",
                                              userInfo: .errorUserInfoDictionary(),
                                              diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            let tokenizationComponent = KlarnaTokenizationComponent(paymentMethod: paymentMethod)
            return PrimerHeadlessKlarnaComponent(tokenizationComponent: tokenizationComponent)
        }
    }
}
