//
//  StringExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 10/3/21.
//

import Foundation

internal extension String {

    var withoutWhiteSpace: String {
        return self.replacingOccurrences(of: " ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isNumeric: Bool {
        guard !self.isEmpty else { return false }
        let nums: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        return Set(self).isSubset(of: nums)
    }

    var isValidCardNumber: Bool {
        let clearedCardNumber = self.withoutNonNumericCharacters

        let cardNetwork = CardNetwork(cardNumber: clearedCardNumber)
        if let cardNumberValidation = cardNetwork.validation {
            if !cardNumberValidation.lengths.contains(clearedCardNumber.count) {
                return false
            }
        }

        let isValid = clearedCardNumber.count >= 13 && clearedCardNumber.count <= 19 && clearedCardNumber.isValidLuhn

        if !isValid {
            let event = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: "Invalid cardnumber",
                    messageType: .validationFailed,
                    severity: .warning))
            Analytics.Service.record(event: event)
        }

        return isValid
    }

    var isHttpOrHttpsURL: Bool {
        let canCreateURL = URL(string: self) != nil
        let startsWithHttpOrHttps = hasPrefix("http") || hasPrefix("https")
        return canCreateURL && startsWithHttpOrHttps
    }

    var withoutNonNumericCharacters: String {
        return withoutWhiteSpace.filter("0123456789".contains)
    }

    var isValidExpiryDate: Bool {
        // swiftlint:disable identifier_name
        let _self = self.replacingOccurrences(of: "/", with: "")
        // swiftlint:enable identifier_name
        if _self.count != 4 {
            return false
        }

        if !_self.isNumeric {
            return false
        }

        guard let date = _self.toDate(withFormat: "MMyy") else { return false }
        let isValid = date.endOfMonth > Date()

        if !isValid {
            let event = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: "Invalid expiry date",
                    messageType: .validationFailed,
                    severity: .error))
            Analytics.Service.record(event: event)
        }

        return isValid
    }

    func isTypingValidCVV(cardNetwork: CardNetwork?) -> Bool? {
        let maxDigits = cardNetwork?.validation?.code.length ?? 4
        if !isNumeric && !isEmpty { return false }
        if count > maxDigits { return false }
        if count >= 3 && count <= maxDigits { return true }
        return nil
    }

    func isValidCVV(cardNetwork: CardNetwork?) -> Bool {
        if !self.isNumeric {
            return false
        }

        if let numberOfDigits = cardNetwork?.validation?.code.length {
            return count == numberOfDigits
        }

        let isValid = count > 2 && count < 5

        if !isValid {
            let event = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: "Invalid CVV",
                    messageType: .validationFailed,
                    severity: .warning))
            Analytics.Service.record(event: event)
        }

        return isValid
    }

    var isValidNonDecimalString: Bool {
        if isEmpty { return false }
        return rangeOfCharacter(from: .decimalDigits) == nil
    }

    var isValidPostalCode: Bool {
        if count < 1 { return false }
        let set = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ '`~.-1234567890")
        return !(self.rangeOfCharacter(from: set.inverted) != nil)
    }

    var isValidLuhn: Bool {
        var sum = 0
        let digitStrings = self.withoutWhiteSpace.reversed().map { String($0) }

        for tuple in digitStrings.enumerated() {
            if let digit = Int(tuple.element) {
                let odd = tuple.offset % 2 == 1

                switch (odd, digit) {
                case (true, 9):
                    sum += 9
                case (true, 0...8):
                    sum += (digit * 2) % 9
                default:
                    sum += digit
                }
            } else {
                return false
            }
        }
        return sum % 10 == 0
    }

    var decodedJWTToken: DecodedJWTToken? {
        let components = self.split(separator: ".")
        if components.count < 2 { return nil }
        let segment = String(components[1]).base64IOSFormat
        guard !segment.isEmpty, let data = Data(base64Encoded: segment, options: .ignoreUnknownCharacters) else { return nil }
        return try? JSONParser().parse(DecodedJWTToken.self, from: data)
    }

    private var base64IOSFormat: Self {
        let str = self.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let offset = str.count % 4
        guard offset != 0 else { return str }
        return str.padding(toLength: str.count + 4 - offset, withPad: "=", startingAt: 0)
    }

    var base64RFC4648Format: Self {
        let str = self.replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
        return str
    }

    func toDate(withFormat format: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ", timeZone: TimeZone? = nil) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = timeZone == nil ? TimeZone(abbreviation: "UTC") : timeZone
        return dateFormatter.date(from: self)
    }

    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }

    func separate(every: Int, with separator: String) -> String {
        return String(stride(from: 0, to: Array(self).count, by: every).map {
            Array(Array(self)[$0..<min($0 + every, Array(self).count)])
        }.joined(separator: separator))
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

    func validateExpiryDateString() throws {
        if self.isEmpty {
            let err = PrimerValidationError.invalidExpiryDate(
                message: "Expiry date cannot be blank.",
                userInfo: [
                    "file": #file,
                    "class": "\(Self.self)",
                    "function": #function,
                    "line": "\(#line)"
                ],
                diagnosticsId: UUID().uuidString)
            throw err

        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/yyyy"

            if let expiryDate = dateFormatter.date(from: self) {
                if !expiryDate.isValidExpiryDate {
                    let err = PrimerValidationError.invalidExpiryDate(
                        message: "Card expiry date is not valid. Expiry date should not be less than a year in the past.",
                        userInfo: [
                            "file": #file,
                            "class": "\(Self.self)",
                            "function": #function,
                            "line": "\(#line)"
                        ],
                        diagnosticsId: UUID().uuidString)
                    throw err
                }

            } else {
                let err = PrimerValidationError.invalidExpiryDate(
                    message: "Card expiry date is not valid. Valid expiry date format is MM/YYYY.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString)
                throw err
            }
        }
    }

    func compareWithVersion(_ otherVersion: String) -> ComparisonResult {
        let versionDelimiter = "."

        var versionComponents = self.components(separatedBy: versionDelimiter)
        var otherVersionComponents = otherVersion.components(separatedBy: versionDelimiter)

        let zeroDiff = versionComponents.count - otherVersionComponents.count

        if zeroDiff == 0 {
            return self.compare(otherVersion, options: .numeric)
        } else {
            let zeros = Array(repeating: "0", count: abs(zeroDiff))
            if zeroDiff > 0 {
                otherVersionComponents.append(contentsOf: zeros)
            } else {
                versionComponents.append(contentsOf: zeros)
            }
            return versionComponents.joined(separator: versionDelimiter)
                .compare(otherVersionComponents.joined(separator: versionDelimiter), options: .numeric)
        }
    }

    var isValidCountryCode: Bool {
        let pattern = "^\\+\\d{1,3}(-\\d{1,4})?$"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let matches = regex?.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
        return matches?.count ?? 0 > 0
    }

    var isValidMobilePhoneNumber: Bool {
        let sanitizedInput = self.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        let pattern = "^\\d{7,15}$"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let matches = regex?.matches(in: sanitizedInput, options: [], range: NSRange(location: 0, length: sanitizedInput.count))
        return matches?.count ?? 0 > 0
    }

    var isValidOTP: Bool {
        let pattern = "^\\d{6}$"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let matches = regex?.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
        return matches?.count ?? 0 > 0
    }
}
