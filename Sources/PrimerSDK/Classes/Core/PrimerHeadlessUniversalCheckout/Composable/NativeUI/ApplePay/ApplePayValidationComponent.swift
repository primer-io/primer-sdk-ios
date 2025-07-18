//
//  File.swift
//  PrimerSDK
//
//  Created by Niall Quinn on 12/02/24.
//

import Foundation

struct ApplePayValidationComponent: NativeUIValidateable {
    let paymentMethodType = PrimerPaymentMethodType.applePay.rawValue

    func validatePaymentMethod() throws {
        if PrimerSettings.current.paymentMethodOptions.applePayOptions == nil {
            throw handled(primerError: .invalidValue(key: "settings.paymentMethodOptions.applePayOptions"))
        }
    }
}
