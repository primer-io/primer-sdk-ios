//
//  TestData.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Centralized test data for CheckoutComponents tests.
/// All test data is organized by category for easy discovery and use.
@available(iOS 15.0, *)
enum TestData {

    // MARK: - Tokens

    enum Tokens {
        static let valid = "test-token"
        static let invalid = "invalid-token"
        static let expired = "expired-token"
        static let token1 = "token-1"
        static let token2 = "token-2"
        static let token3 = "token-3"
    }

    // MARK: - Client Tokens (Alias for Tokens)

    typealias ClientTokens = Tokens

    // MARK: - Merchant IDs

    enum MerchantIds {
        static let valid = "merchant-123"
        static let alternate = "merchant-456"
        static let test = "test-123"
        static let merchant1 = "merchant-1"
        static let merchant2 = "merchant-2"
        static let defaultId = "default"
    }

    // MARK: - API Keys

    enum APIKeys {
        static let valid = "api-key-456"
        static let sandbox = "pk_sandbox_test123"
        static let live = "pk_live_abc123def456"
        static let invalidFormat = "invalid key with spaces"
    }

    // MARK: - Cache Keys

    enum CacheKeys {
        static let configuration = "configuration"
        static let payment = "payment"
        static let merchantConfig = "merchant-config"
        static let key = "key"
        static let key1 = "key-1"
        static let key2 = "key-2"
        static let key3 = "key-3"
        static let key4 = "key-4"
        static let legacy = "legacy"
        static let current = "current"
        static let complex = "complex"
        static let expiring = "expiring"
        static let large = "large"
        static let corrupt = "corrupt"
    }

    // MARK: - Environments

    enum Environments {
        static let production = "production"
        static let sandbox = "sandbox"
        static let invalid = "invalid-env"
    }

    // MARK: - Delays

    enum Delays {
        static let short: TimeInterval = 0.05
        static let medium: TimeInterval = 0.1
        static let expiration: TimeInterval = 0.1
        static let expirationWait: UInt64 = 200_000_000  // 200ms in nanoseconds
    }

    // MARK: - TTL (Time To Live)

    enum TTL {
        static let fiveMinutes: TimeInterval = 300
        static let oneMinute: TimeInterval = 60
        static let justBeforeExpiry: TimeInterval = 299
        static let justAfterExpiry: TimeInterval = 301
        static let justAfterOneMinute: TimeInterval = 61
        static let twoMinutes: TimeInterval = 120
        static let refreshInterval: TimeInterval = 100
    }

    // MARK: - IDs

    enum Ids {
        static let payment = "123"
        static let payment1 = "1"
        static let payment2 = "2"
        static let payment3 = "3"
        static let version1 = "v1"
        static let version2 = "v2"
        static let version3 = "v3"
        static let large = "large"
    }

    // MARK: - Max Entries

    enum MaxEntries {
        static let small = 3
        static let concurrentOperations = 10
        static let concurrentUpdates = 5
    }

    // MARK: - Data Sizes

    enum DataSizes {
        static let maxDataSize = 5_000_000  // 5MB
        static let tooLargeSize = 10_000_000  // 10MB
        static let largeArrayCount = 10000
        static let metadataMaxLength = 1000
    }

    // MARK: - Card Numbers

    enum CardNumbers {
        // Valid card numbers (pass Luhn check)
        static let validVisa = "4242424242424242"
        static let validVisaAlternate = "4111111111111111"
        static let validVisaDebit = "4000056655665556"
        static let validMastercard = "5555555555554444"
        static let validMastercardDebit = "5200828282828210"
        static let validAmex = "378282246310005"
        static let validDiscover = "6011111111111117"
        static let validDiners = "3056930009020004"
        static let validJCB = "3566002020360505"

        // Invalid card numbers
        static let invalidLuhn = "4242424242424241"
        static let invalidLuhnVisa = "4111111111111112"
        static let tooShort = "424242"
        static let tooLong = "42424242424242424242"
        static let empty = ""
        static let nonNumeric = "4242abcd42424242"
        static let withSpaces = "4242 4242 4242 4242"

        // Declined/error cards
        static let declined = "4000000000000002"

        // Co-badged card (Visa + Mastercard)
        static let coBadgedVisa = "4000002500001001"
    }

    // MARK: - Expiry Dates

    enum ExpiryDates {
        /// Returns a valid future expiry date (current month + 2 years)
        static var validFuture: (month: String, year: String) {
            let calendar = Calendar.current
            let date = calendar.date(byAdding: .year, value: 2, to: Date())!
            let month = calendar.component(.month, from: date)
            let year = calendar.component(.year, from: date)
            return (String(format: "%02d", month), String(year % 100))
        }

        /// Returns the current month expiry (still valid)
        static var currentMonth: (month: String, year: String) {
            let calendar = Calendar.current
            let month = calendar.component(.month, from: Date())
            let year = calendar.component(.year, from: Date())
            return (String(format: "%02d", month), String(year % 100))
        }

        /// Returns an expired date (last month)
        static var expired: (month: String, year: String) {
            let calendar = Calendar.current
            let date = calendar.date(byAdding: .month, value: -1, to: Date())!
            let month = calendar.component(.month, from: date)
            let year = calendar.component(.year, from: date)
            return (String(format: "%02d", month), String(year % 100))
        }

        // Invalid formats
        static let invalidMonth = ("13", "25")
        static let zeroMonth = ("00", "25")
        static let empty = ("", "")
    }

    // MARK: - CVV

    enum CVV {
        // Valid CVVs
        static let valid3Digit = "123"
        static let valid4Digit = "1234"  // For Amex

        // Invalid CVVs
        static let tooShort = "12"
        static let tooLong = "12345"
        static let empty = ""
        static let nonNumeric = "12a"
        static let withSpaces = "1 23"
    }

    // MARK: - Cardholder Names

    enum CardholderNames {
        // Valid names
        static let valid = "John Doe"
        static let validWithMiddle = "John Michael Doe"
        static let validSingleName = "Madonna"
        static let validWithAccents = "José García"
        static let validWithHyphen = "Mary-Jane Watson"

        // Invalid names
        static let withNumbers = "John Doe 3rd"
        static let onlyNumbers = "12345"
        static let empty = ""
        static let tooShort = "J"
    }

    // MARK: - Billing Address

    enum BillingAddress {
        static let completeUS: [String: String] = [
            "firstName": "John",
            "lastName": "Doe",
            "addressLine1": "123 Main Street",
            "addressLine2": "Apt 4B",
            "city": "New York",
            "state": "NY",
            "postalCode": "10001",
            "countryCode": "US"
        ]

        static let completeUK: [String: String] = [
            "firstName": "Jane",
            "lastName": "Smith",
            "addressLine1": "10 Downing Street",
            "city": "London",
            "postalCode": "SW1A 2AA",
            "countryCode": "GB"
        ]

        static let minimalRequired: [String: String] = [
            "firstName": "John",
            "lastName": "Doe",
            "addressLine1": "123 Main Street",
            "city": "New York",
            "postalCode": "10001",
            "countryCode": "US"
        ]

        static let empty: [String: String] = [:]

        static let missingRequired: [String: String] = [
            "firstName": "John"
            // Missing lastName, addressLine1, etc.
        ]
    }

    // MARK: - Email Addresses

    enum EmailAddresses {
        // Valid emails
        static let valid = "test@example.com"
        static let validWithSubdomain = "user@mail.example.com"
        static let validWithPlus = "user+tag@example.com"

        // Invalid emails
        static let missingAt = "testexample.com"
        static let missingDomain = "test@"
        static let missingLocal = "@example.com"
        static let empty = ""
        static let invalidFormat = "not an email"
    }

    // MARK: - Phone Numbers

    enum PhoneNumbers {
        // Valid phone numbers
        static let validUS = "1234567890"
        static let validWithCountryCode = "+14155551234"
        static let validInternational = "+442071234567"

        // Invalid phone numbers
        static let tooShort = "123"
        static let empty = ""
        static let withLetters = "123ABC4567"
    }

    // MARK: - Postal Codes

    enum PostalCodes {
        // Valid postal codes
        static let validUS = "10001"
        static let validUSExtended = "10001-1234"
        static let validUK = "SW1A 2AA"
        static let validCanada = "M5V 3L9"

        // Invalid postal codes
        static let empty = ""
        static let tooShort = "123"
    }

    // MARK: - Payment Amounts

    enum Amounts {
        static let standard = 1000          // $10.00
        static let small = 100              // $1.00
        static let large = 100000           // $1,000.00
        static let withSurcharge = 2000     // $20.00
        static let zero = 0
    }

    // MARK: - Currencies

    enum Currencies {
        static let usd = "USD"
        static let eur = "EUR"
        static let gbp = "GBP"
        static let jpy = "JPY"
        static let defaultDecimalDigits = 2
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

    // MARK: - Payment Results

    /// Payment processing outcome fixtures
    enum PaymentResults {
        /// Successful payment completion
        static let success = (
            status: "success",
            transactionId: "test-payment-123",
            error: nil as Error?,
            threeDSRequired: false,
            surchargeAmount: nil as Int?
        )

        /// Payment requires 3DS challenge
        static let threeDSRequired = (
            status: "pending",
            transactionId: "test-payment-456",
            error: nil as Error?,
            threeDSRequired: true,
            surchargeAmount: nil as Int?
        )

        /// Payment declined by issuer
        static let declined = (
            status: "failure",
            transactionId: nil as String?,
            error: NSError(
                domain: "PaymentError",
                code: 402,
                userInfo: [NSLocalizedDescriptionKey: "Payment declined: Insufficient funds"]
            ) as Error,
            threeDSRequired: false,
            surchargeAmount: nil as Int?
        )

        /// Payment with network surcharge
        static let withSurcharge = (
            status: "success",
            transactionId: "test-payment-789",
            error: nil as Error?,
            threeDSRequired: false,
            surchargeAmount: 50 as Int? // 50 cents
        )

        /// Payment cancelled by user
        static let cancelled = (
            status: "cancelled",
            transactionId: nil as String?,
            error: NSError(
                domain: "PaymentError",
                code: -999,
                userInfo: [NSLocalizedDescriptionKey: "Payment cancelled by user"]
            ) as Error,
            threeDSRequired: false,
            surchargeAmount: nil as Int?
        )
    }

    // MARK: - 3DS Flows

    /// 3D Secure challenge scenario fixtures
    enum ThreeDSFlows {
        /// Challenge required - user must complete 3DS authentication
        static let challengeRequired = (
            transactionId: "test-tx-123",
            acsTransactionId: "test-acs-456",
            acsReferenceNumber: "test-ref-789",
            acsSignedContent: "signed-content-challenge",
            challengeRequired: true,
            outcome: "success"
        )

        /// Frictionless flow - 3DS completed without user interaction
        static let frictionless = (
            transactionId: "test-tx-234",
            acsTransactionId: "test-acs-567",
            acsReferenceNumber: "test-ref-890",
            acsSignedContent: nil as String?,
            challengeRequired: false,
            outcome: "success"
        )

        /// Failed 3DS authentication
        static let failed = (
            transactionId: "test-tx-345",
            acsTransactionId: "test-acs-678",
            acsReferenceNumber: "test-ref-901",
            acsSignedContent: "signed-content-failed",
            challengeRequired: true,
            outcome: "failure"
        )

        /// User cancelled 3DS challenge
        static let cancelled = (
            transactionId: "test-tx-456",
            acsTransactionId: "test-acs-789",
            acsReferenceNumber: "test-ref-012",
            acsSignedContent: "signed-content-cancelled",
            challengeRequired: true,
            outcome: "cancelled"
        )

        /// 3DS challenge timed out
        static let timeout = (
            transactionId: "test-tx-567",
            acsTransactionId: "test-acs-890",
            acsReferenceNumber: "test-ref-123",
            acsSignedContent: "signed-content-timeout",
            challengeRequired: true,
            outcome: "timeout"
        )
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

    // MARK: - Card Networks

    enum Networks {
        static let visa = CardNetwork.visa
        static let mastercard = CardNetwork.masterCard
        static let amex = CardNetwork.amex
        static let discover = CardNetwork.discover
        static let unknown = CardNetwork.unknown
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
