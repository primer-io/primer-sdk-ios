//
//  PrimerHeadlessUniversalCheckoutAchManager.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

extension PrimerHeadlessUniversalCheckout {
    public final class AchManager: NSObject {
        public var mandateDelegate: ACHMandateDelegate?
        // swiftlint:disable generic_type_name
        public func provide<PrimerHeadlessAchComponent>(paymentMethodType: String) throws -> PrimerHeadlessAchComponent?
        // swiftlint:enable generic_type_name
        where PrimerCollectableData: Any, PrimerHeadlessStep: Any {
            try provideStripeAchUserDetailsComponent(paymentMethodType: paymentMethodType) as? PrimerHeadlessAchComponent
        }

        public func provideStripeAchUserDetailsComponent(paymentMethodType: String) throws -> (any StripeAchUserDetailsComponent)? {
            guard let paymentMethod = PrimerAPIConfiguration.paymentMethodConfigs?
                    .first(where: { $0.type == paymentMethodType })
            else {
                throw handled(
                    primerError: .unsupportedPaymentMethod(
                        paymentMethodType: paymentMethodType,
                        userInfo: .errorUserInfoDictionary(
                            additionalInfo: ["message": "Unable to locate a valid payment method configuration"]
                        )
                    )
                )
            }

            guard let tokenizationViewModel = paymentMethod.tokenizationViewModel as? StripeAchTokenizationViewModel else {
                throw handled(
                    primerError: .unsupportedPaymentMethod(
                        paymentMethodType: paymentMethodType,
                        userInfo: .errorUserInfoDictionary(
                            additionalInfo: ["message": "Unable to locate a valid payment method view model."]
                        )
                    )
                )
            }

            mandateDelegate = tokenizationViewModel
            return StripeAchHeadlessComponent(tokenizationViewModel: tokenizationViewModel)
        }
    }
}
