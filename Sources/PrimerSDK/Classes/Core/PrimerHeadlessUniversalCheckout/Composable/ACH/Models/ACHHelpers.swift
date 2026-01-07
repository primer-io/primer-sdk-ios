//
//  ACHHelpers.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
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
        handled(primerError: .invalidClientToken())
    }

    static func getInvalidSettingError(name: String) -> PrimerError {
        handled(primerError: .invalidValue(key: name))
    }

    static func getInvalidValueError(key: String, value: Any? = nil) -> PrimerError {
        handled(primerError: .invalidValue(key: key, value: value))
    }

    static func getCancelledError(paymentMethodType: String) -> PrimerError {
        handled(primerError: .cancelled(paymentMethodType: paymentMethodType))
    }

    static func getMissingSDKError(sdk: String) -> PrimerError {
        handled(primerError: .missingSDK(paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue, sdkName: sdk))
    }

}
