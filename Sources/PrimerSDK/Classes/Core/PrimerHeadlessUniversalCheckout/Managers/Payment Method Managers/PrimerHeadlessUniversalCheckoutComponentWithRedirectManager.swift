//
//  PrimerHeadlessIdealManager.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 03.11.2023.
//

import Foundation
extension PrimerHeadlessUniversalCheckout {
    @objc public class ComponentWithRedirectManager: NSObject {
        @objc public func provideComponent(paymentMethodType: String) -> PrimerHeadlessBanksComponentWrapper {
            PrimerHeadlessBanksComponentWrapper(manager: self, paymentMethodType: paymentMethodType)
        }
        @available(iOS 13, *)
        public func provide<PrimerHeadlessMainComponent>(paymentMethodType: String) throws -> PrimerHeadlessMainComponent? 
		where PrimerCollectableData: Any, PrimerHeadlessStep: Any {
            try provideBanksComponent(paymentMethodType: paymentMethodType) as? PrimerHeadlessMainComponent
        }
		
        public func provideBanksComponent(paymentMethodType: String) throws -> any PrimerHeadlessMainComponent {
            guard let paymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodType),
                  paymentMethodType == .adyenIDeal else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            guard let tokenizationModel = try getPaymentMethodTokenizationModel() as? BankSelectorTokenizationProviding else {
                let err = PrimerError.generic(message: "Unable to locate a correct payment method view model", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            guard let webDelegate = try getPaymentMethodTokenizationModel() as? WebRedirectTokenizationDelegate else {
                let err = PrimerError.generic(message: "Unable to locate a correct payment method view model", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            return DefaultBanksComponent(paymentMethodType: paymentMethodType, tokenizationProvingModel: tokenizationModel) {
                webDelegate.setup()
                return WebRedirectComponent(paymentMethodType: paymentMethodType, tokenizationModelDelegate: webDelegate)
            }
        }

        private func getPaymentMethodTokenizationModel() throws -> PaymentMethodTokenizationModelProtocol? {
            try PrimerAPIConfiguration.paymentMethodConfigs?
                .filter({ $0.isEnabled })
                .filter({ $0.baseLogoImage != nil })
                .compactMap({
                    do {
                        try $0.tokenizationModel?.validate()
                    } catch {
                        let err = PrimerError.generic(message: "Unable to locate a valid payment method view model", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        throw err
                    }
                    return $0.tokenizationModel
                })
                .first
        }
    }
}
