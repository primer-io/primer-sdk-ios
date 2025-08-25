//
//  PrimerHeadlessUniversalCheckoutComponentWithRedirectManager.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

private typealias TokenizationViewModelType = (
    BankSelectorTokenizationProviding &
    WebRedirectTokenizationDelegate &
    PaymentMethodTokenizationModelProtocol
)

import Foundation
extension PrimerHeadlessUniversalCheckout {
    @objc public final class ComponentWithRedirectManager: NSObject {

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
                throw handled(primerError: .unsupportedPaymentMethod(paymentMethodType: paymentMethodType))
            }

            guard let tokenizationModel = try getTokenizationModel() else {
                throw handled(
                    primerError: .unsupportedPaymentMethod(
                        paymentMethodType: paymentMethodType.rawValue,
                        reason: "Unable to locate a correct payment method view model"
                    )
                )
            }

            return DefaultBanksComponent(paymentMethodType: paymentMethodType, tokenizationProvidingModel: tokenizationModel) {
                tokenizationModel.setupNotificationObservers()
                return WebRedirectComponent(paymentMethodType: paymentMethodType, tokenizationModelDelegate: tokenizationModel)
            }
        }

        private func getTokenizationModel() throws -> TokenizationViewModelType? {
            let viewModel = PrimerAPIConfiguration.paymentMethodConfigs?
                .filter { $0.isEnabled }
                .filter { $0.baseLogoImage != nil }
                .compactMap { $0.tokenizationModel as? TokenizationViewModelType }
                .first

            guard let viewModel = viewModel else {
                return nil
            }

            try viewModel.validate()
            return viewModel
        }
    }
}
