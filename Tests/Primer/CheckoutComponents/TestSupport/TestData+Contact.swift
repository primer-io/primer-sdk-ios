//
//  TestData+Contact.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
extension TestData {

    // MARK: - Names

    enum Names {
        static let firstName = "John"
        static let lastName = "Doe"
    }

    // MARK: - First Names

    enum FirstNames {
        static let valid = "John"
        static let withAccents = "François"
        static let withUnicode = "René"
        static let empty = ""
        static let singleCharacter = "J"
    }

    // MARK: - Last Names

    enum LastNames {
        static let valid = "Doe"
        static let withApostrophe = "O'Connor"
        static let withHyphen = "Smith-Jones"
        static let empty = ""
        static let singleCharacter = "D"
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
}
