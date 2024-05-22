//
//  PayPalValidationComponent.swift
//  PrimerSDK
//
//  Created by Niall Quinn on 12/02/24.
//

import Foundation

struct PayPalValidationComponent: NativeUIValidateable {
    let paymentMethodType = PrimerPaymentMethodType.payPal.rawValue

    func validatePaymentMethod() throws {
        try _ = PrimerSettings.current.paymentMethodOptions.validUrlForUrlScheme()
    }
}
