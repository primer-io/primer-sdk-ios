//
//  PrimerHeadlessIdealManager.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 03.11.2023.
//

import Foundation
extension PrimerHeadlessUniversalCheckout {
    public class PrimerHeadlessFormWithRedirectManager: NSObject {
        public func provideBanksComponent(paymentMethodType: String) -> BanksComponent? {
            guard let paymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodType) else {
                return nil
            }
            guard paymentMethodType == .adyenIDeal else {
                return nil
            }
            guard let tokenizationViewModel = PrimerAPIConfiguration.paymentMethodConfigViewModels.first(where: { $0 is BankSelectorTokenizationViewModel }) as? BankSelectorTokenizationViewModel  else {
                return nil
            }
            return BanksComponent.init(paymentMethodType: paymentMethodType, tokenizationViewModel: tokenizationViewModel) {
                return WebRedirectComponent()
            }
        }
    }
}
