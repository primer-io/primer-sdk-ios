//
//  StringExtension.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerCore
import PrimerFoundation
import PrimerNetworking

extension String {

    var isValidCardNumber: Bool {
        let clearedCardNumber = withoutNonNumericCharacters

        let cardNetwork = CardNetwork(cardNumber: clearedCardNumber)
        if let cardNumberValidation = cardNetwork.validation {
            if !cardNumberValidation.lengths.contains(clearedCardNumber.count) {
                return false
            }
        }

        let isValid = clearedCardNumber.count >= 13 && clearedCardNumber.count <= 19 && clearedCardNumber.isValidLuhn

        if !isValid {
            let event = Analytics.Event.message(
                message: "Invalid cardnumber",
                messageType: .validationFailed,
                severity: .warning
            )
            Analytics.Service.fire(event: event)
        }

        return isValid
    }

    var isValidExpiryDate: Bool {
        // swiftlint:disable identifier_name
        let _self = replacingOccurrences(of: "/", with: "")
        // swiftlint:enable identifier_name
        if _self.count != 4 {
            return false
        }

        if !_self.isNumeric {
            return false
        }

        guard let date = _self.toDate(withFormat: "MMyy") else { return false }
        let isValid = date.isValidExpiryDate

        if !isValid {
            let event = Analytics.Event.message(
                message: "Invalid expiry date",
                messageType: .validationFailed,
                severity: .error
            )
            Analytics.Service.fire(event: event)
        }

        return isValid
    }

    func isTypingValidCVV(cardNetwork: CardNetwork?) -> Bool? {
        let maxDigits = cardNetwork?.validation?.code.length ?? 4
        if !isNumeric, !isEmpty { return false }
        if count > maxDigits { return false }
        if count >= 3, count <= maxDigits { return true }
        return nil
    }

    func isValidCVV(cardNetwork: CardNetwork?) -> Bool {
        if !isNumeric {
            return false
        }

        if let numberOfDigits = cardNetwork?.validation?.code.length {
            return count == numberOfDigits
        }

        let isValid = count > 2 && count < 5

        if !isValid {
            let event = Analytics.Event.message(
                message: "Invalid CVV",
                messageType: .validationFailed,
                severity: .warning
            )
            Analytics.Service.fire(event: event)
        }

        return isValid
    }

    var isValidPostalCode: Bool {
        if count < 1 { return false }
        let set = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ '`~.-1234567890")
        return !(rangeOfCharacter(from: set.inverted) != nil)
    }

    var decodedJWTToken: DecodedJWTToken? {
        let components = split(separator: ".")
        if components.count < 2 { return nil }
        let segment = String(components[1]).base64IOSFormat
        guard !segment.isEmpty, let data = Data(base64Encoded: segment,
                                                options: .ignoreUnknownCharacters)
        else { return nil }
        return try? JSONDecoder().decode(DecodedJWTToken.self, from: data)
    }

    private var base64IOSFormat: Self {
        let str = replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let offset = str.count % 4
        guard offset != 0 else { return str }
        return str.padding(toLength: str.count + 4 - offset,
                           withPad: "=", startingAt: 0)
    }

    func isValidPhoneNumberForPaymentMethodType(_ paymentMethodType: PrimerPaymentMethodType) -> Bool {

        var regex = ""

        switch paymentMethodType {
        case .xenditOvo:
            regex = "^(^\\+628|628)(\\d{8,10})"
        default:
            regex = "^(^\\+)(\\d){9,14}$"
        }

        let phoneNumber = NSPredicate(format: "SELF MATCHES %@", regex)
        return phoneNumber.evaluate(with: self)
    }

    /// Validates expiry date string in MM/YY or MM/YYYY format
    /// - Throws: PrimerValidationError if the date format is invalid or the date is expired
    /// - Note: This function accepts both MM/YY and MM/YYYY formats to maintain compatibility
    ///         between Drop-in UI (MM/YY) and Headless/RawDataManager (MM/YYYY) implementations
    func validateExpiryDateString() throws {
        if isEmpty {
            throw PrimerValidationError.invalidExpiryDate(message: "Expiry date cannot be blank.")

        } else {
            var expiryDate: Date?

            // Try MM/yy format first
            let shortFormatter = DateFormatter()
            shortFormatter.dateFormat = "MM/yy"
            shortFormatter.locale = Locale(identifier: "en_US_POSIX")

            if let date = shortFormatter.date(from: self) {
                expiryDate = date
            } else {
                // Try MM/yyyy format
                let longFormatter = DateFormatter()
                longFormatter.dateFormat = "MM/yyyy"
                longFormatter.locale = Locale(identifier: "en_US_POSIX")
                expiryDate = longFormatter.date(from: self)
            }

            guard let expiryDate, expiryDate.yearComponentAsString.normalizedFourDigitYear() != nil else {
                throw PrimerValidationError.invalidExpiryDate(
                    message: "Card expiry date is not valid. Valid expiry date formats are MM/YY or MM/YYYY."
                )
            }

            if !expiryDate.isValidExpiryDate {
                throw PrimerValidationError.invalidExpiryDate(
                    message: "Card expiry date is not valid. Expiry date should not be less than a year in the past."
                )
            }
        }
    }

    // MARK: - NSRange Text Processing Utilities

    /// Safely converts NSRange to Range<String.Index>
    /// - Parameter nsRange: The NSRange to convert
    /// - Returns: The corresponding Range<String.Index>, or nil if conversion fails
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        print("[DEBUG] range(from:) input: '\(self)', nsRange: \(nsRange)")
        let result = Range(nsRange, in: self)

        if let result {
            let substring = String(self[result])
            print("[DEBUG] range(from:) converted successfully, substring: '\(substring)'")
        } else {
            print("[DEBUG] range(from:) conversion failed")
        }

        return result
    }

    /// Replaces characters in the given NSRange with a replacement string
    /// - Parameters:
    ///   - nsRange: The range of characters to replace
    ///   - replacement: The string to insert in place of the characters
    /// - Returns: A new string with the replacement applied, or the original string if the range is invalid
    func replacingCharacters(in nsRange: NSRange, with replacement: String) -> String {
        print("[DEBUG] replacingCharacters input: '\(self)', nsRange: \(nsRange), replacement: '\(replacement)'")

        guard let range = range(from: nsRange) else {
            print("[DEBUG] Failed to convert NSRange to Range, returning original string")
            return self
        }

        let result = replacingCharacters(in: range, with: replacement)
        print("[DEBUG] replacingCharacters result: '\(result)'")
        return result
    }

    /// Calculates the unformatted position from a formatted text position
    /// Useful for mapping cursor positions when text contains separator characters
    /// - Parameters:
    ///   - formattedIndex: The index in the formatted text (including separators)
    ///   - separator: The separator character used in formatting (e.g., " " for card numbers, "/" for expiry dates)
    /// - Returns: The corresponding index in the unformatted text (excluding separators)
    func unformattedPosition(from formattedIndex: Int, separator: Character) -> Int {
        print("[DEBUG] unformattedPosition input: '\(self)', formattedIndex: \(formattedIndex), separator: '\(separator)'")

        var unformattedPos = 0
        for i in 0..<min(formattedIndex, count) {
            let charIndex = index(startIndex, offsetBy: i)
            if self[charIndex] != separator {
                unformattedPos += 1
            }
        }

        print("[DEBUG] unformattedPosition result: \(unformattedPos)")
        return unformattedPos
    }
}
