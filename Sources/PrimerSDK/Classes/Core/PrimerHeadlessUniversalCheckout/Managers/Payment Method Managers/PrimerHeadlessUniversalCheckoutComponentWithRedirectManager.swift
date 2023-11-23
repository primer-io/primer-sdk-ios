//
//  PrimerHeadlessIdealManager.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 03.11.2023.
//

import Foundation
extension PrimerHeadlessUniversalCheckout {
    @objc public class ComponentWithRedirectManager: NSObject {
        @objc public func provideComponent(paymentMethodType: String) -> PrimerHeadlessMainComponentWrapper {
            PrimerHeadlessMainComponentWrapper(manager: self, paymentMethodType: paymentMethodType)
        }
        @available(iOS 13, *)
        public func provide<PrimerHeadlessMainComponent>(paymentMethodType: String) throws -> PrimerHeadlessMainComponent? where PrimerCollectableData: Any, PrimerHeadlessStep: Any {
            try provideBanksComponent(paymentMethodType: paymentMethodType) as? PrimerHeadlessMainComponent
        }
        public func provideBanksComponent(paymentMethodType: String) throws -> any PrimerHeadlessMainComponent {
            guard let paymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodType),
                  paymentMethodType == .adyenIDeal else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            guard let tokenizationModelDelegate = PrimerAPIConfiguration.paymentMethodConfigViewModels.first(where: { $0 is BankSelectorTokenizationDelegate }) as? BankSelectorTokenizationDelegate else {
                let err = PrimerError.generic(message: "Unable to locate a correct payment method view model", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            guard let webDelegate = PrimerAPIConfiguration.paymentMethodConfigViewModels.first(where: { $0 is WebRedirectTokenizationDelegate }) as? WebRedirectTokenizationDelegate else {
                let err = PrimerError.generic(message: "Unable to locate a correct payment method view model", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            return DefaultBanksComponent(paymentMethodType: paymentMethodType, tokenizationModelDelegate: tokenizationModelDelegate) {
                webDelegate.setup()
                return WebRedirectComponent(paymentMethodType: paymentMethodType, tokenizationModelDelegate: webDelegate)
            }
        }
    }
}
