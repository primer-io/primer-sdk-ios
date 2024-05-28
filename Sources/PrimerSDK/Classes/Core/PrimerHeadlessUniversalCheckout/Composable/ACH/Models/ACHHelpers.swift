//
//  ACHHelpers.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 30.04.2024.
//

import UIKit

// ACHHelpers: A utility structure to facilitate various operations related to ACH payment sessions.
struct ACHHelpers {
    
    /// - Helper function to construct locale data.
    static func constructLocaleData() -> Request.Body.StripeAch.SessionData {
        return Request.Body.StripeAch.SessionData(locale: PrimerSettings.current.localeData.localeCode,
                                               platform: "IOS")
    }
    
    static func getACHPaymentInstrument(paymentMethod: PrimerPaymentMethod) -> ACHPaymentInstrument? {
        let sessionInfo = constructLocaleData()
        
        switch paymentMethod.type {
        case "STRIPE_ACH":
            return ACHPaymentInstrument(paymentMethodConfigId: paymentMethod.id ?? "",
                                                               paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue,
                                                               authenticationProvider: PrimerPaymentMethodType.stripeAch.provider,
                                                               type: PaymentInstrumentType.stripeAch.rawValue,
                                                               sessionInfo: sessionInfo)
        default:
            return nil
        }
    }
    
    // MARK: - Error helpers
    static func getInvalidTokenError() -> PrimerError {
        let error = PrimerError.invalidClientToken(
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString
        )
        ErrorHandler.handle(error: error)
        return error
    }
    
    static func getInvalidSettingError(
        name: String
    ) -> PrimerError {
        let error = PrimerError.invalidSetting(
            name: name,
            value: nil,
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString
        )
        ErrorHandler.handle(error: error)
        return error
    }
    
    static func getInvalidValueError(
        key: String,
        value: Any? = nil
    ) -> PrimerError {
        let error = PrimerError.invalidValue(
            key: key,
            value: value,
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString
        )
        ErrorHandler.handle(error: error)
        return error
    }
    
    static func getCancelledError(paymentMethodType: String) -> PrimerError {
        let error = PrimerError.cancelled(
            paymentMethodType: paymentMethodType,
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId:  UUID().uuidString)
        ErrorHandler.handle(error: error)
        return error
    }
    
    static func getPaymentFailedError(paymentMethodType: String) -> PrimerError {
        let error = PrimerError.paymentFailed(
            paymentMethodType: paymentMethodType,
            description: "Failed to create payment",
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString)
        ErrorHandler.handle(error: error)
        return error
    }
    
    static func getFailedToProcessPaymentError(paymentMethodType: String, paymentResponse: Response.Body.Payment) -> PrimerError {
        let error = PrimerError.failedToProcessPayment(
            paymentMethodType: paymentMethodType,
            paymentId: paymentResponse.id ?? "nil",
            status: paymentResponse.status.rawValue,
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString)
        ErrorHandler.handle(error: error)
        return error
    }
    
    static func getMissingSDKError(sdk: String) -> PrimerError {
        let error = PrimerError.missingSDK(
            paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue,
            sdkName: sdk,
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString)
        ErrorHandler.handle(error: error)
        return error
    }
    
}
