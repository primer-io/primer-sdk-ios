//
//  NativeUIManager.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

extension PrimerHeadlessUniversalCheckout {

    public final class NativeUIManager: PrimerPaymentMethodManager {

        public let paymentMethodType: String

        private var paymentMethod: PrimerPaymentMethod?
        private let validationComponent: NativeUIValidateable
        private let presentationComponent: NativeUIPresentable

        public required init(paymentMethodType: String) throws {
            PrimerInternal.shared.sdkIntegrationType = .headless

            let sdkEvent = Analytics.Event.sdk(
                name: "\(Self.self).\(#function)",
                params: [
                    "category": "NATIVE_UI",
                    "intent": PrimerInternal.shared.intent?.rawValue ?? "null",
                    "paymentMethodType": paymentMethodType
                ]
            )
            Analytics.Service.fire(events: [sdkEvent])

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
        private func validatePaymentMethod(
            withType paymentMethodType: String,
            andIntent intent: PrimerSessionIntent? = nil
        ) throws -> PrimerPaymentMethod {
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

            Analytics.Service.fire(events: [sdkEvent])

            do {
                try validatePaymentMethod(withType: paymentMethodType, andIntent: intent)
            } catch {
                throw error
            }

            presentationComponent.present(
                intent: intent,
                clientToken: PrimerAPIConfigurationModule.clientToken!
            )
        }

        private func cancel() {
            paymentMethod?.tokenizationViewModel?.cancel()
        }
    }

}
