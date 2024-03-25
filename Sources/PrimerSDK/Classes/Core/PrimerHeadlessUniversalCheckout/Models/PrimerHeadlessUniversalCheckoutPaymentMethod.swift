//
//  PrimerHeadlessUniversalCheckoutPaymentMethod.swift
//  PrimerSDK
//
//  Created by Evangelos on 27/9/22.
//

// swiftlint:disable nesting

import Foundation
import PassKit

extension PrimerHeadlessUniversalCheckout {

    public class PaymentMethod: NSObject {

        /// To enhance your experience and provide consistent functionality across our services,
        /// some features are available in both our Headless and Drop-In interfaces.
        /// While Drop-In automatically utilizes these features through predefined settings,
        /// the Headless interface offers you the flexibility to enable these features manually.
        /// This is made possible through the introduction of the "PrimerAvailablePaymentMethodsOptions".
        /// This option allows you to customize your Headless setup by enabling specific features
        /// that align with the capabilities available in the Drop-In interface.
        public struct PrimerAvailablePaymentMethodsOptions {
            let captureVaultedCardCvv: Bool?
        }

        static var availablePaymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod] {
            var availablePaymentMethods = PrimerAPIConfiguration.paymentMethodConfigs?
                .compactMap({ $0.type })
                .compactMap({ PrimerHeadlessUniversalCheckout.PaymentMethod(paymentMethodType: $0) })

            if PrimerSettings.current.paymentMethodOptions.applePayOptions?.showApplePayForUnsupportedDevice != true {
                if !PKPaymentAuthorizationController.canMakePayments() {
                    // Filter out Apple pay from payment methods
                    availablePaymentMethods = availablePaymentMethods?.filter({ (method: PrimerHeadlessUniversalCheckout.PaymentMethod) in
                        return method.paymentMethodType != "APPLE_PAY"
                    })
                }
            }

            return availablePaymentMethods ?? []
        }

        public private(set) var paymentMethodType: String
        public private(set) var supportedPrimerSessionIntents: [PrimerSessionIntent] = []
        public private(set) var paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory]
        public private(set) var requiredInputDataClass: PrimerRawData.Type?
        public private(set) var options: PrimerHeadlessUniversalCheckout.PaymentMethod.PrimerAvailablePaymentMethodsOptions

        init?(paymentMethodType: String) {
            guard let paymentMethod = PrimerAPIConfiguration.paymentMethodConfigs?
                    .first(where: { $0.type == paymentMethodType })
            else {
                return nil
            }

            self.paymentMethodType = paymentMethodType

            if paymentMethod.isCheckoutEnabled {
                supportedPrimerSessionIntents.append(.checkout)
            }

            if paymentMethod.isVaultingEnabled {
                supportedPrimerSessionIntents.append(.vault)
            }

            guard let paymentMethodManagerCategories = paymentMethod.paymentMethodManagerCategories else {
                return nil
            }
            self.paymentMethodManagerCategories = paymentMethodManagerCategories

            if PrimerPaymentMethodType.paymentCard.rawValue == paymentMethodType {
                requiredInputDataClass = PrimerCardData.self
            }

            let captureVaultedCardCvv = (paymentMethod.options as? CardOptions)?.captureVaultedCardCvv ?? false
            options = PrimerAvailablePaymentMethodsOptions(captureVaultedCardCvv: captureVaultedCardCvv)

            super.init()
        }
    }
}
// swiftlint:enable nesting
