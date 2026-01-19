//
//  NativeUIValidateable.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

protocol NativeUIValidateable {
    var paymentMethodType: String { get }

    // Common - Implemented as extension
    func validate(intent: PrimerSessionIntent?) throws -> PrimerPaymentMethod

    // Implemented per payment method
    func validatePaymentMethod() throws
}

extension NativeUIValidateable {

    @discardableResult
    func validate(intent: PrimerSessionIntent?) throws -> PrimerPaymentMethod {
        guard PrimerAPIConfigurationModule.decodedJWTToken != nil,
              PrimerAPIConfigurationModule.apiConfiguration != nil
        else {
            throw handled(primerError: .uninitializedSDKSession())
        }

        guard let paymentMethod = PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods?.first(where: { $0.type == paymentMethodType }) else {
            throw handled(primerError: .unsupportedPaymentMethod(paymentMethodType: paymentMethodType))
        }

        guard let cats = paymentMethod.paymentMethodManagerCategories, cats.contains(.nativeUI) else {
            throw handled(
                primerError: .unsupportedPaymentMethodForManager(
                    paymentMethodType: paymentMethod.type,
                    category: PrimerPaymentMethodManagerCategory.nativeUI.rawValue
                )
            )
        }

        if let intent = intent {
            if (intent == .vault && !paymentMethod.isVaultingEnabled) ||
                (intent == .checkout && !paymentMethod.isCheckoutEnabled) {
                throw handled(primerError: .unsupportedIntent(intent: intent))
            }
        }

        try validatePaymentMethod()

        return paymentMethod
    }
}

// Used currently for all web redirect APMs
// There is no specific validation on top of the default implementation
struct GenericValidationComponent: NativeUIValidateable {
    var paymentMethodType: String

    func validatePaymentMethod() throws {}
}
