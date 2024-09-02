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
    static func constructLocaleData(paymentMethod: PrimerPaymentMethod) -> Request.Body.StripeAch.SessionData {
        switch paymentMethod.internalPaymentMethodType {
        case .stripeAch:
            return Request.Body.StripeAch.SessionData(locale: PrimerSettings.current.localeData.localeCode,
                                                      platform: "IOS")
        default:
            return Request.Body.StripeAch.SessionData(locale: nil, platform: nil)
        }
        
    }
    
    static func getACHPaymentInstrument(paymentMethod: PrimerPaymentMethod) -> ACHPaymentInstrument? {
        let sessionInfo = constructLocaleData(paymentMethod: paymentMethod)
        
        switch paymentMethod.internalPaymentMethodType {
        case .stripeAch:
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
        let error = PrimerError.invalidValue(
            key: name,
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
