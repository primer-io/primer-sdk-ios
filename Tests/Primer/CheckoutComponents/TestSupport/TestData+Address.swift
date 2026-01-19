//
//  TestData+Address.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

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

    // MARK: - Postal Codes

    enum PostalCodes {
        // Valid postal codes
        static let validUS = "10001"
        static let validUSExtended = "10001-1234"
        static let validUK = "SW1A 2AA"
        static let validCanada = "M5V 3L9"
        static let validGeneric3Chars = "123"
        static let validGeneric10Chars = "1234567890"

        // Invalid postal codes
        static let empty = ""
        static let tooShort = "12"
        static let tooLong = "12345678901"
        static let usWithLetters = "1000A"
        static let invalidCanadian = "12345"
        static let ukTooShort = "SW1"
    }

    // MARK: - Country Codes

    enum CountryCodes {
        static let us = "US"
        static let usLowercase = "us"
        static let ca = "CA"
        static let gb = "GB"
        static let gbLowercase = "gb"
        static let usa3Letter = "USA"
        static let empty = ""
        static let singleCharacter = "U"
        static let tooLong = "USAA"
    }

    // MARK: - OTP Codes

    enum OTPCodes {
        static let valid6Digit = "123456"
        static let valid4Digit = "1234"
        static let tooShort = "1234"
        static let withNonNumeric = "12345a"
        static let empty = ""
        static let expectedLength6 = 6
    }

    // MARK: - Cities

    enum Cities {
        static let valid = "New York"
        static let withHyphen = "Winston-Salem"
        static let withPeriod = "St. Louis"
        static let empty = ""
        static let singleCharacter = "A"
    }

    // MARK: - States

    enum States {
        static let validAbbreviation = "NY"
        static let validFullName = "New York"
        static let empty = ""
        static let singleCharacter = "N"
    }

    // MARK: - Addresses

    enum Addresses {
        static let valid = "123 Main Street"
        static let valid3Chars = "ABC"
        static let valid100Chars = String(repeating: "a", count: 100)
        static let tooShort = "AB"
        static let tooLong = String(repeating: "a", count: 101)
        static let empty = ""
    }
}
