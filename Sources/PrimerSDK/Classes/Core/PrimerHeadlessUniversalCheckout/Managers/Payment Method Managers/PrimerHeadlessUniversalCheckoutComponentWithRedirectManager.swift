//
//  PrimerHeadlessIdealManager.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 03.11.2023.
//

import Foundation
extension PrimerHeadlessUniversalCheckout {
    @objc public class ComponentWithRedirectManager: NSObject {

        typealias TokenizationViewModelType = BankSelectorTokenizationProviding & WebRedirectTokenizationDelegate

        @objc public func provideComponent(paymentMethodType: String) -> PrimerHeadlessBanksComponentWrapper {
            PrimerHeadlessBanksComponentWrapper(manager: self, paymentMethodType: paymentMethodType)
        }

        public func provide<MainComponent>(paymentMethodType: String) throws -> MainComponent?

        where PrimerCollectableData: Any, PrimerHeadlessStep: Any {
            try provideBanksComponent(paymentMethodType: paymentMethodType) as? MainComponent
        }

        public func provideBanksComponent(paymentMethodType: String) throws -> any PrimerHeadlessMainComponent {
            guard let paymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodType),
                  paymentMethodType == .adyenIDeal else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType,
                                                               userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            guard let tokenizationModel = try getPaymentMethodTokenizationModel(ofType: BankSelectorTokenizationProviding.self) as? TokenizationViewModelType else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType.rawValue,
                                                               userInfo: .errorUserInfoDictionary(additionalInfo: [
                                                                   "message": "Unable to locate a correct payment method view model"
                                                               ]),
                                                               diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            return DefaultBanksComponent(paymentMethodType: paymentMethodType, tokenizationProvidingModel: tokenizationModel) {
                tokenizationModel.setupNotificationObservers()
                return WebRedirectComponent(paymentMethodType: paymentMethodType, tokenizationModelDelegate: tokenizationModel)
            }
        }

        private func getPaymentMethodTokenizationModel<T>(ofType type: T.Type) throws -> T? {
            let vm = PrimerAPIConfiguration.paymentMethodConfigs?
                .filter { $0.isEnabled }
                .filter { $0.baseLogoImage != nil }
                .compactMap { $0.tokenizationModel as? T }
                .first

            guard let vm = vm else {
                return nil
            }

            try (vm as? PaymentMethodTokenizationModelProtocol)?.validate()
            return vm
        }
    }
}
