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
        if PrimerSettings.current.paymentMethodOptions.urlScheme == nil {
            let error = PrimerError.invalidUrlScheme(urlScheme: nil,
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
