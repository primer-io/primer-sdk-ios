//
//  TestData.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Organized by category for easy discovery and use.
@available(iOS 15.0, *)
enum TestData {

    // MARK: - Accessibility

    enum Accessibility {
        // Test configuration
        static let concurrentOperationCount = 10
        static let testTimeout: TimeInterval = 5.0
        static let testQueueLabel = "test.concurrent"
        static let concurrentExpectationDescription = "Concurrent announcements"

        // Announcement messages for tests
        static let errorPrefix = "Error"
        static let statePrefix = "State"
        static let errorMessage = "Error message"
        static let stateChangeMessage = "State change"
        static let layoutChangeMessage = "Layout change"
        static let screenChangeMessage = "Screen change"

        // Test case descriptions
        static let errorDescription = "Error announcements"
        static let stateChangeDescription = "State change announcements"
        static let layoutChangeDescription = "Layout change announcements"
        static let screenChangeDescription = "Screen change announcements"
    }

    // MARK: - Tokens

    enum Tokens {
        static let valid = "test-token"
        static let invalid = "invalid-token"
        static let expired = "expired-token"
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

    // MARK: - Card Networks

    enum Networks {
        static let visa = CardNetwork.visa
        static let mastercard = CardNetwork.masterCard
        static let amex = CardNetwork.amex
        static let discover = CardNetwork.discover
        static let unknown = CardNetwork.unknown
    }

    // MARK: - Dependency Injection

    enum DI {
        static let defaultValue = "default"
        static let fallbackValue = "fallback"
        static let resolvedValue = "resolved_value"
        static let envResolvedValue = "env_resolved"
        static let resolveTestValue = "resolve_test"
        static let defaultIdentifier = "default"
        static let fallbackIdentifier = "fallback"
        static let fromContainerIdentifier = "from-container"
        static let cachedPrefix = "cached-"
        static let protocolFallbackValue = "protocol_fallback"
        static let observableDefaultValue = "observable_default"
        static let envFallbackValue = "env_fallback"
        static let fallbackValueAlternate = "fallback_value"
    }

    // MARK: - DI Container

    enum DIContainer {
        enum Timing {
            static let oneSecondNanoseconds: UInt64 = 1_000_000_000
            static let oneMillisecondNanoseconds: UInt64 = 1_000_000
        }

        enum Duration {
            static let oneMs: TimeInterval = 0.001
            static let twoMs: TimeInterval = 0.002
            static let threeMs: TimeInterval = 0.003
            static let fiveMs: TimeInterval = 0.005
            static let tenMs: TimeInterval = 0.010
        }

        enum Factory {
            static let testIdPrefix = "test-"
            static let syncIdPrefix = "sync-"
            static let voidIdPrefix = "void-"
            static let syncVoidIdPrefix = "sync-void-"
            static let asyncSyncIdPrefix = "async-sync-"
            static let defaultMultiplier = 10
            static let largeMultiplier = 100
            static let factoryName1 = "factory-1"
            static let factoryName2 = "factory-2"
            static let namedClosure = "named-closure"
            static let closureTestId = "closure-test"
        }

        enum Values {
            static let expectedValue = 42
            static let multiplier3 = 3
            static let multiplier4 = 4
            static let multiplier5 = 5
            static let multiplier7 = 7
        }
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

    // MARK: - Payment Method Options

    enum PaymentMethodOptions {
        static let monthlySubscription = "Monthly subscription"
        static let testSubscription = "Test Subscription"
        static let subscription = "Subscription"
        static let exampleMerchantId = "merchant.com.example.app"
        static let testMerchantId = "merchant.test"
        static let testMerchantName = "Test Merchant"
        static let myAppUrlScheme = "myapp://payment"
        static let testAppUrl = "testapp://payment"
        static let testAppUrlTrailing = "testapp://"
        static let testAppScheme = "testapp"
        static let myAppScheme = "myapp"
    }

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
}

// MARK: - Test Error Type

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
