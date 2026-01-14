//
//  TestData+Errors.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
extension TestData {

    // MARK: - Errors

    enum Errors {
        // Network errors
        static let networkError = NSError(
            domain: "TestError",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Network connection failed"]
        )

        static let networkTimeout = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorTimedOut,
            userInfo: [NSLocalizedDescriptionKey: "Request timed out"]
        )

        // Validation errors
        static let validationError = NSError(
            domain: "ValidationError",
            code: 400,
            userInfo: [NSLocalizedDescriptionKey: "Validation failed"]
        )

        static let invalidCardNumber = NSError(
            domain: "PrimerValidationError",
            code: 1001,
            userInfo: [
                NSLocalizedDescriptionKey: "Invalid card number",
                "field": "cardNumber"
            ]
        )

        static let expiredCard = NSError(
            domain: "PrimerValidationError",
            code: 1002,
            userInfo: [
                NSLocalizedDescriptionKey: "Card has expired",
                "field": "expiryDate"
            ]
        )

        static let invalidCVV = NSError(
            domain: "PrimerValidationError",
            code: 1003,
            userInfo: [
                NSLocalizedDescriptionKey: "Invalid CVV",
                "field": "cvv"
            ]
        )

        // Payment errors
        static let paymentDeclined = NSError(
            domain: "PaymentError",
            code: 402,
            userInfo: [NSLocalizedDescriptionKey: "Payment was declined"]
        )

        static let insufficientFunds = NSError(
            domain: "PaymentError",
            code: 4001,
            userInfo: [NSLocalizedDescriptionKey: "Payment declined: Insufficient funds"]
        )

        static let fraudCheck = NSError(
            domain: "PaymentError",
            code: 4002,
            userInfo: [NSLocalizedDescriptionKey: "Payment declined: Fraud check failed"]
        )

        // Server errors
        static let serverError = NSError(
            domain: "ServerError",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Internal server error"]
        )

        // Configuration errors
        static let invalidMerchantConfig = NSError(
            domain: "ConfigurationError",
            code: 5001,
            userInfo: [NSLocalizedDescriptionKey: "Invalid merchant configuration"]
        )

        static let missingAPIKey = NSError(
            domain: "ConfigurationError",
            code: 5002,
            userInfo: [NSLocalizedDescriptionKey: "Missing API key"]
        )

        // 3DS errors
        static let threeDSInitializationFailed = NSError(
            domain: "Primer3DSError",
            code: 6001,
            userInfo: [NSLocalizedDescriptionKey: "3DS initialization failed"]
        )

        static let threeDSChallengeTimeout = NSError(
            domain: "Primer3DSError",
            code: 6002,
            userInfo: [NSLocalizedDescriptionKey: "3DS challenge timed out"]
        )

        static let threeDSChallengeCancelled = NSError(
            domain: "Primer3DSError",
            code: 6003,
            userInfo: [NSLocalizedDescriptionKey: "3DS challenge was cancelled"]
        )

        // Auth errors
        static let authenticationRequired = NSError(
            domain: "AuthError",
            code: 401,
            userInfo: [NSLocalizedDescriptionKey: "Authentication required"]
        )

        // Generic errors
        static let unknown = NSError(
            domain: "UnknownError",
            code: 9999,
            userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred"]
        )
    }
}
