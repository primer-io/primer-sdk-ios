//
//  PrimerHeadlessIdealManager.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 03.11.2023.
//

import Foundation
extension PrimerHeadlessUniversalCheckout {
    public class ComponentWithRedirectManager: NSObject {
        public func provide<PrimerHeadlessMainComponent>(paymentMethodType: String) -> PrimerHeadlessMainComponent? where PrimerCollectableData: Any, PrimerHeadlessStep: Any {
            guard let paymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodType),
                  paymentMethodType == .adyenIDeal else {
                return nil
            }
            // guard unsupportedPaymentMethod
            guard let tokenizationModelDelegate = PrimerAPIConfiguration.paymentMethodConfigViewModels.first(where: { $0 is BankSelectorTokenizationDelegate }) as? BankSelectorTokenizationDelegate  else {
                return nil
            }
            return DefaultBanksComponent(paymentMethodType: paymentMethodType, tokenizationModelDelegate: tokenizationModelDelegate) {
                WebRedirectComponent(paymentMethodType: paymentMethodType, tokenizationModelDelegate: tokenizationModelDelegate)
            } as? PrimerHeadlessMainComponent
        }
    }
}
