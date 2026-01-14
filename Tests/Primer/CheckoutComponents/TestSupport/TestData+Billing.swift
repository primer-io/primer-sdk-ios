//
//  TestData+Billing.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
extension TestData {

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

    // MARK: - Names

    enum Names {
        static let firstName = "John"
        static let lastName = "Doe"
        static let fullName = "John Doe"
    }
}
