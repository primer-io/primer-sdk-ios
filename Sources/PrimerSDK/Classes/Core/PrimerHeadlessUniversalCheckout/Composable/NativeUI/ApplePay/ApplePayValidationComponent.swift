//
//  ApplePayValidationComponent.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

struct ApplePayValidationComponent: NativeUIValidateable {
    let paymentMethodType = PrimerPaymentMethodType.applePay.rawValue

    func validatePaymentMethod() throws {
        if PrimerSettings.current.paymentMethodOptions.applePayOptions == nil {
            throw handled(primerError: .invalidValue(key: "settings.paymentMethodOptions.applePayOptions"))
        }
    }
}
