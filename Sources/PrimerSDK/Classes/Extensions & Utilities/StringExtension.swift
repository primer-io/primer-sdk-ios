//
//  StringExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 10/3/21.
//

#if canImport(UIKit)

import Foundation

extension String {

    var withoutWhiteSpace: String {
        return self.replacingOccurrences(of: " ", with: "")
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

    var isValidCardNumber: Bool {
        return count >= 13 && count <= 19 && isValidLuhn
    }

    var isValidEmail: Bool {
        // FIXME: Maybe find (or construct 😆) a better regex
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

    func decodeClientTokenBase64() -> DecodedClientToken {
        let bytes = self.components(separatedBy: ".")
        for element in bytes {
            // decode element, add necessary padding to base64 to ensure it's a multiple of 4 (required by Swift foundation)
            if let decodedData = Data(base64Encoded: element.padding(toLength: ((element.count + 3) / 4) * 4, withPad: "=", startingAt: 0)) {
                let decodedString = String(data: decodedData, encoding: .utf8)!
                if decodedString.contains("\"accessToken\":") {
                    do {
                        print(decodedString)
                        let token = try JSONDecoder().decode(DecodedClientToken.self, from: decodedData)
                        return token
                    } catch {
                        print("error!")
                    }
                }
            }

        }
        return DecodedClientToken()
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

    func toAttributedString(substringsWithAttributes: [String: [NSAttributedString.Key: Any]]) -> NSAttributedString {
        let mutableAttString = NSMutableAttributedString(string: self)
        let text = NSString(string: self)
        substringsWithAttributes.forEach { (arg0) in
            let (key, value) = arg0
            let range = text.range(of: key)
            mutableAttString.addAttributes(value, range: range)
        }
        return mutableAttString
    }

    func localized(comment: String? = nil) -> String {
        return NSLocalizedString(
            self,
            tableName: "Localizable",
            bundle: Bundle.primerFramework,
            value: self,
            comment: comment ?? self
        )
    }

    var isValidAccountNumber: Bool {
        print(!self.isEmpty)
        return !self.isEmpty
    }

}

#endif
