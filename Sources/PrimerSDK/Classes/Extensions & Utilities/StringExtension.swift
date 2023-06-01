//
//  StringExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 10/3/21.
//

#if canImport(UIKit)

import Foundation

internal extension String {

    var withoutWhiteSpace: String {
        return self.replacingOccurrences(of: " ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isNotValidIBAN: Bool {
        return self.withoutWhiteSpace.count < 6
    }

    var urlEscaped: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
    }

    var utf8EncodedData: Data? {
        return data(using: .utf8)
    }

    var utf8EncodedStringRepresentation: String? {
        guard let data = utf8EncodedData else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    var isNumeric: Bool {
        guard !self.isEmpty else { return false }
        let nums: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        return Set(self).isSubset(of: nums)
    }

    var isAlphaNumeric: Bool {
        let regex = "^[a-zA-Z0-9]*$"
        let inputP = NSPredicate(format: "SELF MATCHES %@", regex)
        return inputP.evaluate(with: self)
    }
    
    var isOnlyLatinCharacters: Bool {
        let set = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ")
        return !(self.rangeOfCharacter(from: set.inverted) != nil)
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
    
    var isTypingValidExpiryDate: Bool? {
        // swiftlint:disable identifier_name
        let _self = self.replacingOccurrences(of: "/", with: "")
        // swiftlint:enable identifier_name
        if _self.count > 4 {
            return false
            
        } else if _self.count == 3 {
            return nil
            
        } else if _self.count == 2 {
            if let month = Int(_self) {
                if month < 1 || month > 12 {
                    return false
                } else {
                    return nil
                }
            }
            
        } else if _self.count == 1 {
            if ["0", "1"].contains(_self.prefix(1)) {
                return nil
            } else {
                return false
            }
            
        } else if _self.isEmpty {
            return nil
        }
        
        // Case where count is 4 will arrive here
        guard let date = _self.toDate(withFormat: "MMyy") else { return false }
        return date.endOfMonth > Date()
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
    
    var isValidExpiryDateWith4DigitYear: Bool {
        // swiftlint:disable identifier_name
        let _self = self.replacingOccurrences(of: "/", with: "")
        // swiftlint:enable identifier_name
        if _self.count != 6 {
            return false
        }
        
        if !_self.isNumeric {
            return false
        }
        
        guard let date = _self.toDate(withFormat: "MMyyyy") else { return false }
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
    
    var isTypingNonDecimalCharacters: Bool {
        isValidNonDecimalString
    }
    
    var isValidNonDecimalString: Bool {
        if isEmpty { return false }
        return rangeOfCharacter(from: .decimalDigits) == nil
    }
    
    var isValidCardholderName: Bool {
        return isValidNonDecimalString
    }
    
    var isTypingValidCardholderName: Bool {
        isValidCardholderName
    }
    
    var isValidPostalCode: Bool {
        if count < 1 { return false }
        let set = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ '`~.-1234567890")
        return !(self.rangeOfCharacter(from: set.inverted) != nil)
    }

    var isValidEmail: Bool {
        let emailRegEx = "(?:[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}" +
            "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" +
            "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[\\p{L}0-9](?:[a-" +
            "z0-9-]*[\\p{L}0-9])?\\.)+[\\p{L}0-9](?:[\\p{L}0-9-]*[\\p{L}0-9])?|\\[(?:(?:25[0-5" +
            "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" +
            "9][0-9]?|[\\p{L}0-9-]*[\\p{L}0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" +
            "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        let emailP = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailP.evaluate(with: self)
    }

    var isValidLuhn: Bool {
        var sum = 0
        let digitStrings = self.reversed().map { String($0) }

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
    
    var base64IOSFormat: Self {
        let str = self.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let offset = str.count % 4
        guard offset != 0 else { return str }
        return str.padding(toLength: str.count + 4 - offset, withPad: "=", startingAt: 0)
    }
    
    var base64RFC4648Format: Self {
        let str = self.replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
        return str
    }
    
    func toDate(withFormat f: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ", timeZone: TimeZone? = nil) -> Date? {
        let df = DateFormatter()
        df.dateFormat = f
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = timeZone == nil ? TimeZone(abbreviation: "UTC") : timeZone
        return df.date(from: self)
    }

    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }

    var isValidAccountNumber: Bool {
        return !self.isEmpty
    }
    
    func separate(every: Int, with separator: String) -> String {
        return String(stride(from: 0, to: Array(self).count, by: every).map {
            Array(Array(self)[$0..<min($0 + every, Array(self).count)])
        }.joined(separator: separator))
    }

    func separate(on gaps: [Int], with separator: String) -> String {
        let sortedReversedGaps = gaps.sorted(by: { $0 > $1 })
        
        var str = self
        for gap in sortedReversedGaps {
            if str.count > gap {
                str.insert(" ", at: str.index(str.startIndex, offsetBy: gap))
            }
        }
        
        return str
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    internal func isValidPhoneNumberForPaymentMethodType(_ paymentMethodType: PrimerPaymentMethodType) -> Bool {
        
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
}

#endif
