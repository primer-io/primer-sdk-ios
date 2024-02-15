//
//  NativeUIValidateable.swift
//  PrimerSDK
//
//  Created by Niall Quinn on 12/02/24.
//

import Foundation

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
            let err = PrimerError.uninitializedSDKSession(userInfo: nil, diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard let paymentMethod = PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods?.first(where: { $0.type == paymentMethodType }) else {
            let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: nil, diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard let cats = paymentMethod.paymentMethodManagerCategories, cats.contains(.nativeUI) else {
            let err = PrimerError.unsupportedPaymentMethodForManager(paymentMethodType: paymentMethod.type,
                                                                     category: PrimerPaymentMethodManagerCategory.nativeUI.rawValue,
                                                                     userInfo: nil,
                                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        if let intent = intent {
            if (intent == .vault && !paymentMethod.isVaultingEnabled) ||
                (intent == .checkout && !paymentMethod.isCheckoutEnabled) {
                let err = PrimerError.unsupportedIntent(intent: intent,
                                                        userInfo: ["file": #file,
                                                                   "class": "\(Self.self)",
                                                                   "function": #function,
                                                                   "line": "\(#line)"],
                                                        diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
        }

        try validatePaymentMethod()

        return paymentMethod
    }
}
