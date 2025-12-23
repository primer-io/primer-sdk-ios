//
//  TestData.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Centralized test data for CheckoutComponents tests.
/// All test data is organized by category for easy discovery and use.
@available(iOS 15.0, *)
enum TestData {

    // MARK: - Card Numbers

    enum CardNumbers {
        // Valid card numbers (pass Luhn check)
        static let validVisa = "4242424242424242"
        static let validVisaDebit = "4000056655665556"
        static let validMastercard = "5555555555554444"
        static let validMastercardDebit = "5200828282828210"
        static let validAmex = "378282246310005"
        static let validDiscover = "6011111111111117"
        static let validDiners = "3056930009020004"
        static let validJCB = "3566002020360505"

        // Invalid card numbers
        static let invalidLuhn = "4242424242424241"
        static let tooShort = "424242"
        static let tooLong = "42424242424242424242"
        static let empty = ""
        static let nonNumeric = "4242abcd42424242"
        static let withSpaces = "4242 4242 4242 4242"

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

    // MARK: - Errors

    enum Errors {
        static let networkError = NSError(
            domain: "TestError",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Network connection failed"]
        )

        static let validationError = NSError(
            domain: "ValidationError",
            code: 400,
            userInfo: [NSLocalizedDescriptionKey: "Validation failed"]
        )

        static let serverError = NSError(
            domain: "ServerError",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Internal server error"]
        )

        static let paymentDeclined = NSError(
            domain: "PaymentError",
            code: 402,
            userInfo: [NSLocalizedDescriptionKey: "Payment was declined"]
        )

        static let authenticationRequired = NSError(
            domain: "AuthError",
            code: 401,
            userInfo: [NSLocalizedDescriptionKey: "Authentication required"]
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
