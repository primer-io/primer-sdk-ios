//
//  PaymentMethodNativeUIManager.swift
//  PrimerSDK
//
//  Created by Evangelos on 4/10/22.
//

import Foundation

extension PrimerHeadlessUniversalCheckout {

    public final class NativeUIManager: PrimerPaymentMethodManager {

        public let paymentMethodType: String

        private var paymentMethod: PrimerPaymentMethod?
        private let validationComponent: NativeUIValidateable
        private let presentationComponent: NativeUIPresentable

        required public init(paymentMethodType: String) throws {
            PrimerInternal.shared.sdkIntegrationType = .headless

            let sdkEvent = Analytics.Event.sdk(
                name: "\(Self.self).\(#function)",
                params: [
                    "category": "NATIVE_UI",
                    "intent": PrimerInternal.shared.intent?.rawValue ?? "null",
                    "paymentMethodType": paymentMethodType
                ]
            )
            Analytics.Service.record(events: [sdkEvent])

            switch paymentMethodType {
            case PrimerPaymentMethodType.applePay.rawValue:
                validationComponent = ApplePayValidationComponent()
            case PrimerPaymentMethodType.payPal.rawValue:
                validationComponent = PayPalValidationComponent()
            default:
                validationComponent = GenericValidationComponent(paymentMethodType: paymentMethodType)
            }

            presentationComponent = NativeUIPresentationComponent(paymentMethodType: paymentMethodType)

            self.paymentMethodType = paymentMethodType
            paymentMethod = try validatePaymentMethod(withType: paymentMethodType)

            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            settings.uiOptions.isInitScreenEnabled = false
            settings.uiOptions.isSuccessScreenEnabled = false
            settings.uiOptions.isErrorScreenEnabled = false

        }

        @discardableResult
        private func validatePaymentMethod(withType paymentMethodType: String,
                                           andIntent intent: PrimerSessionIntent? = nil) throws -> PrimerPaymentMethod {
            try validationComponent.validate(intent: intent)
        }

        public func showPaymentMethod(intent: PrimerSessionIntent) throws {
            PrimerInternal.shared.sdkIntegrationType = .headless

            let sdkEvent = Analytics.Event.sdk(
                name: "\(Self.self).\(#function)",
                params: [
                    "category": "NATIVE_UI",
                    "intent": PrimerInternal.shared.intent?.rawValue ?? "null",
                    "paymentMethodType": paymentMethodType
                ]
            )

            Analytics.Service.record(events: [sdkEvent])

            do {
                try validatePaymentMethod(withType: paymentMethodType, andIntent: intent)
            } catch {
                throw error
            }

            presentationComponent.present(intent: intent,
                                               clientToken: PrimerAPIConfigurationModule.clientToken!)
        }

        private func cancel() {
            paymentMethod?.tokenizationViewModel?.cancel()
        }
    }

}
