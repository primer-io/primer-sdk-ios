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
            let error = PrimerError.uninitializedSDKSession(userInfo: nil,
                                                            diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: error)
            throw error
        }

        guard let paymentMethod = PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods?.first(where: { $0.type == paymentMethodType }) else {
            let error = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: nil,
                                                             diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: error)
            throw error
        }

        guard let cats = paymentMethod.paymentMethodManagerCategories, cats.contains(.nativeUI) else {
            let error = PrimerError.unsupportedPaymentMethodForManager(paymentMethodType: paymentMethod.type,
                                                                       category: PrimerPaymentMethodManagerCategory.nativeUI.rawValue,
                                                                       userInfo: nil,
                                                                       diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: error)
            throw error
        }

        if let intent = intent {
            if (intent == .vault && !paymentMethod.isVaultingEnabled) ||
                (intent == .checkout && !paymentMethod.isCheckoutEnabled) {
                let error = PrimerError.unsupportedIntent(intent: intent,
                                                          userInfo: ["file": #file,
                                                                     "class": "\(Self.self)",
                                                                     "function": #function,
                                                                     "line": "\(#line)"],
                                                          diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: error)
                throw error
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
