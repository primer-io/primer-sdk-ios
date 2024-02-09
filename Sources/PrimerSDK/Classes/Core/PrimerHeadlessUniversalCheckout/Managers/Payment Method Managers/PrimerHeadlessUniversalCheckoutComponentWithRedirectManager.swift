//
//  PrimerHeadlessIdealManager.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 03.11.2023.
//

import Foundation
extension PrimerHeadlessUniversalCheckout {
    @objc public class ComponentWithRedirectManager: NSObject {

        typealias BankSelectorWebRedirectTokenization = BankSelectorTokenizationProviding & WebRedirectTokenizationDelegate

        @objc public func provideComponent(paymentMethodType: String) -> PrimerHeadlessBanksComponentWrapper {
            PrimerHeadlessBanksComponentWrapper(manager: self, paymentMethodType: paymentMethodType)
        }

        @available(iOS 13, *)
        public func provide<PrimerHeadlessMainComponent>(paymentMethodType: String) throws -> PrimerHeadlessMainComponent? where PrimerCollectableData: Any, PrimerHeadlessStep: Any {
            try provideBanksComponent(paymentMethodType: paymentMethodType) as? PrimerHeadlessMainComponent
        }

        public func provideBanksComponent(paymentMethodType: String) throws -> any PrimerHeadlessMainComponent {
            guard let paymentMethodTypeEnum = PrimerPaymentMethodType(rawValue: paymentMethodType),
                  paymentMethodTypeEnum == .adyenIDeal else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType,
                                                               userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                                                               diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            guard let tokenizationModel = try getPaymentMethodTokenizationModel(paymentMethodType) as? BankSelectorWebRedirectTokenization else {
                let err = PrimerError.generic(message: "Unable to locate a correct payment method view model",
                                              userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                                              diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            return DefaultBanksComponent(paymentMethodType: paymentMethodTypeEnum, tokenizationProvingModel: tokenizationModel) {
                tokenizationModel.setup()
                return WebRedirectComponent(paymentMethodType: paymentMethodTypeEnum, tokenizationModelDelegate: tokenizationModel)
            }
        }

        private func getPaymentMethodTokenizationModel(_ paymentMethodType: String) throws -> PaymentMethodTokenizationModelProtocol? {

            guard let paymentMethodConfig = PrimerAPIConfiguration.paymentMethodConfigs?.first(where: { $0.type == paymentMethodType }),
                  let tokenizationModel = paymentMethodConfig.banksTokenizationModel else {
                let err = PrimerError.generic(message: "Unable to locate a valid payment method view model",
                                              userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                                              diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            do {
                try tokenizationModel.validate()
            }
            return tokenizationModel
        }

    }
}

private extension PrimerPaymentMethod {
    var banksTokenizationModel: PaymentMethodTokenizationModelProtocol? {
        switch internalPaymentMethodType {
        case .adyenIDeal:
            return BanksTokenizationComponent(config: self)
        default: return nil
        }
    }
}
