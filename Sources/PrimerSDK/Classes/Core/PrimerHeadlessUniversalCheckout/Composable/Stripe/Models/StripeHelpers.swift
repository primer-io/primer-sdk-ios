//
//  StripeHelpers.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 30.04.2024.
//

import UIKit

// StripeHelpers: A utility structure to facilitate various operations related to Stripe ACH payment sessions.
struct StripeHelpers {
    
    /// - Helper function to construct locale data.
    static func constructLocaleData() -> Request.Body.StripeAch.SessionData {
        return Request.Body.StripeAch.SessionData(locale: PrimerSettings.current.localeData.localeCode,
                                               platform: "IOS")
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
    
    static func getCancelledError() -> PrimerError {
        let error = PrimerError.cancelled(
            paymentMethodType: "STRIPE_ACH",
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId:  UUID().uuidString)
        ErrorHandler.handle(error: error)
        return error
    }
    
    static func getPaymentFailedError() -> PrimerError {
        let error = PrimerError.paymentFailed(
            paymentMethodType: "STRIPE_ACH",
            description: "Failed to create payment",
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString)
        ErrorHandler.handle(error: error)
        return error
    }
    
    static func getFailedToProcessPaymentError(paymentResponse: Response.Body.Payment) -> PrimerError {
        let error = PrimerError.failedToProcessPayment(
            paymentMethodType: "STRIPE_ACH",
            paymentId: paymentResponse.id ?? "nil",
            status: paymentResponse.status.rawValue,
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString)
        ErrorHandler.handle(error: error)
        return error
    }
    
    static func getInvalidUrlSchemeError(settings: PrimerSettingsProtocol) -> PrimerError {
        let error = PrimerError.invalidUrlScheme(
            urlScheme: settings.paymentMethodOptions.urlScheme,
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString)
        ErrorHandler.handle(error: error)
        return error
    }
    
    static func getMissingSDKError() -> PrimerError {
        let error = PrimerError.missingSDK(
            paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue,
            sdkName: "StripeSDK",
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString)
        ErrorHandler.handle(error: error)
        return error
    }
    
}
