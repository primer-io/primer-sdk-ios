//
//  PrimerHeadlessIdealManager.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 03.11.2023.
//

import Foundation
extension PrimerHeadlessUniversalCheckout {
    public class PrimerHeadlessFormWithRedirectManager: NSObject {
        let paymentMethodType: PrimerPaymentMethodType
        public init?(paymentMethodType: String) {
            guard let paymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodType) else {
                return nil
            }
            guard paymentMethodType == .adyenIDeal else {
                return nil
            }
            self.paymentMethodType = paymentMethodType
        }
        public func provideBanksComponent() -> BanksComponent? {
            guard let tokenizationModelDelegate = PrimerAPIConfiguration.paymentMethodConfigViewModels.first(where: { $0 is BankSelectorTokenizationDelegate }) as? BankSelectorTokenizationDelegate  else {
                return nil
            }
            return BanksComponent(paymentMethodType: paymentMethodType, tokenizationModelDelegate: tokenizationModelDelegate, createWebRedirectComponent: {
                WebRedirectComponent(paymentMethodType: self.paymentMethodType, tokenizationModelDelegate: tokenizationModelDelegate)
            }) { result in
                print("Did finish with result")
            }
        }
    }
}
