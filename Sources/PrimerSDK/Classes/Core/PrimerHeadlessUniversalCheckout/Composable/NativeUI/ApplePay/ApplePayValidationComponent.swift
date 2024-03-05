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
            let error = PrimerError.invalidValue(key: "settings.paymentMethodOptions.applePayOptions",
                                               value: nil,
                                               userInfo: ["file": #file,
                                                          "class": "\(Self.self)",
                                                          "function": #function,
                                                          "line": "\(#line)"],
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: error)
            throw error
        }
    }
}
