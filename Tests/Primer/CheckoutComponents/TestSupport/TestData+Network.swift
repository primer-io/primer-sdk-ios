//
//  TestData+Network.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
extension TestData {

    // MARK: - Tokens

    enum Tokens {
        static let valid = "test-token"
        static let invalid = "invalid-token"
        static let expired = "expired-token"
    }

    // MARK: - API Responses

    /// Mock API responses for repository testing
    enum APIResponses {
        /// Valid payment methods response with full configuration
        static let validPaymentMethods = """
        {
            "paymentMethods": [
                {
                    "id": "PAYMENT_CARD",
                    "type": "PAYMENT_CARD",
                    "name": "Card",
                    "isEnabled": true,
                    "supportedCardNetworks": ["VISA", "MASTERCARD", "AMEX"]
                }
            ]
        }
        """

        /// Empty payment methods array (edge case)
        static let emptyPaymentMethods = """
        {
            "paymentMethods": []
        }
        """

        /// Malformed JSON to test error handling
        static let malformedJSON = "{invalid json}"

        /// Valid merchant configuration response
        static let merchantConfig = """
        {
            "merchantId": "test-merchant-123",
            "settings": {
                "theme": "light",
                "enableAnalytics": true
            }
        }
        """

        /// Error response from API
        static let errorResponse = """
        {
            "error": {
                "code": "PAYMENT_DECLINED",
                "message": "Insufficient funds"
            }
        }
        """
    }

    // MARK: - Network Responses

    /// Mock network response fixtures for testing repository network layer
    enum NetworkResponses {
        private static let testURL = URL(string: "https://api.primer.io/test")!
        private static let defaultHeaders = ["Content-Type": "application/json"]

        /// Successful HTTP 200 response
        static func success200(with data: Data? = nil) -> (Data?, HTTPURLResponse?, Error?) {
            let json = data ?? APIResponses.validPaymentMethods.data(using: .utf8)
            let response = HTTPURLResponse(
                url: testURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: defaultHeaders
            )
            return (json, response, nil)
        }

        /// Client error - 400 Bad Request
        static let badRequest400 = (
            data: nil as Data?,
            response: HTTPURLResponse(
                url: testURL,
                statusCode: 400,
                httpVersion: nil,
                headerFields: defaultHeaders
            ),
            error: nil as Error?
        )

        /// Client error - 401 Unauthorized
        static let unauthorized401 = (
            data: nil as Data?,
            response: HTTPURLResponse(
                url: testURL,
                statusCode: 401,
                httpVersion: nil,
                headerFields: defaultHeaders
            ),
            error: nil as Error?
        )

        /// Client error - 404 Not Found
        static let notFound404 = (
            data: nil as Data?,
            response: HTTPURLResponse(
                url: testURL,
                statusCode: 404,
                httpVersion: nil,
                headerFields: defaultHeaders
            ),
            error: nil as Error?
        )

        /// Server error - 500 Internal Server Error
        static let serverError500 = (
            data: nil as Data?,
            response: HTTPURLResponse(
                url: testURL,
                statusCode: 500,
                httpVersion: nil,
                headerFields: defaultHeaders
            ),
            error: nil as Error?
        )

        /// Network timeout error
        static let timeout = (
            data: nil as Data?,
            response: nil as HTTPURLResponse?,
            error: NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorTimedOut,
                userInfo: [NSLocalizedDescriptionKey: "Request timed out"]
            ) as Error
        )

        /// No connection error (offline)
        static let noConnection = (
            data: nil as Data?,
            response: nil as HTTPURLResponse?,
            error: NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorNotConnectedToInternet,
                userInfo: [NSLocalizedDescriptionKey: "No internet connection"]
            ) as Error
        )
    }

    // MARK: - Errors

    enum Errors {
        // Network Errors
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

        // Validation Errors
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

        // Payment Errors
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

        // Server Errors
        static let serverError = NSError(
            domain: "ServerError",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Internal server error"]
        )

        // Configuration Errors
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

        // 3DS Errors
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

        // Authentication Errors
        static let authenticationRequired = NSError(
            domain: "AuthError",
            code: 401,
            userInfo: [NSLocalizedDescriptionKey: "Authentication required"]
        )

        // Generic Errors
        static let unknown = NSError(
            domain: "UnknownError",
            code: 9999,
            userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred"]
        )
    }
}

// MARK: - Test Error Type

/// Custom error type for test scenarios
enum TestError: Error, Equatable {
    case timeout
    case cancelled
    case validationFailed(String)
    case networkFailure
    case unknown

    var localizedDescription: String {
        switch self {
        case .timeout:
            return "Operation timed out"
        case .cancelled:
            return "Operation was cancelled"
        case let .validationFailed(message):
            return "Validation failed: \(message)"
        case .networkFailure:
            return "Network request failed"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
