//
//  PaymentMethodNativeUIManager.swift
//  PrimerSDK
//
//  Created by Evangelos on 4/10/22.
//

import Foundation

extension PrimerHeadlessUniversalCheckout {

    public class NativeUIManager: PrimerPaymentMethodManager {

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
                self.validationComponent = ApplePayValidationComponent()
            case PrimerPaymentMethodType.payPal.rawValue:
                self.validationComponent = PayPalValidationComponent()
            default:
                self.validationComponent = GenericValidationComponent(paymentMethodType: paymentMethodType)
            }

            self.presentationComponent = NativeUIPresentationComponent(paymentMethodType: paymentMethodType)

            self.paymentMethodType = paymentMethodType
            self.paymentMethod = try self.validatePaymentMethod(withType: paymentMethodType)

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
                try self.validatePaymentMethod(withType: self.paymentMethodType, andIntent: intent)
            } catch {
                throw error
            }

            self.presentationComponent.present(intent: intent,
                                               clientToken: PrimerAPIConfigurationModule.clientToken!)
        }

        private func cancel() {
            self.paymentMethod?.tokenizationViewModel?.cancel()
        }
    }

}

struct GenericValidationComponent: NativeUIValidateable {
    var paymentMethodType: String
    
    func validatePaymentMethod() throws {}
}
