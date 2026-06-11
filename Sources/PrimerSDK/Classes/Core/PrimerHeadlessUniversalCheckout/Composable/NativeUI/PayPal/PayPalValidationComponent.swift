//
//  PayPalValidationComponent.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation

struct PayPalValidationComponent: NativeUIValidateable {
    let paymentMethodType = PrimerPaymentMethodType.payPal.rawValue

    func validatePaymentMethod() throws {
        try _ = PrimerSettings.current.paymentMethodOptions.validUrlForUrlScheme()
    }
}
