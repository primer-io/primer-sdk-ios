//
//  TestData+Config.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
extension TestData {

    // MARK: - Analytics

    enum Analytics {
        static let checkoutSessionId = "checkout-session"
        static let sdkVersion = "0.0.1"
        static let tokenSessionId = "token-session-id"
        static let tokenAccountId = "token-account-id"
    }

    // MARK: - JWT

    enum JWT {
        static let sandboxEnv = "SANDBOX"
        static let productionEnv = "PRODUCTION"
    }

    // MARK: - Locale

    enum Locale {
        static let spanish = "es"
        static let mexico = "MX"
        static let spanishMexico = "es-MX"
        static let french = "fr"
        static let france = "FR"
        static let frenchFrance = "fr-FR"
        static let german = "de"
        static let germany = "DE"
        static let germanGermany = "de-DE"
        static let japanese = "ja"
        // Legacy aliases for backward compatibility
        static let frenchLanguageCode = "fr"
        static let franceRegionCode = "FR"
        static let frenchFranceLocaleCode = "fr-FR"
    }

    // MARK: - Diagnostics IDs

    enum DiagnosticsIds {
        static let test = "test-diagnostics-123"
        static let validation = "validation-diagnostics-456"
    }

    // MARK: - Error Keys

    enum ErrorKeys {
        static let test = "test-error-key"
        static let cardNumber = "cardNumber"
        static let expiry = "expiry"
        static let cvv = "cvv"
    }
}
