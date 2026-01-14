//
//  TestData+Cards.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
extension TestData {

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

    // MARK: - Card Networks

    enum Networks {
        static let visa = CardNetwork.visa
        static let mastercard = CardNetwork.masterCard
        static let amex = CardNetwork.amex
        static let discover = CardNetwork.discover
        static let unknown = CardNetwork.unknown
    }
}
