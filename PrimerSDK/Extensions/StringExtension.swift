//
//  StringExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 5/3/21.
//

import Foundation

internal extension String {
    
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    var urlEscaped: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
    }
    
    var utf8Encoded: Data? {
        return data(using: .utf8)
    }
    
    var isNumeric: Bool {
        guard self.count > 0 else { return false }
        let nums: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        return Set(self).isSubset(of: nums)
    }
    
    var isAlphaNumeric: Bool {
        let regex = "^[a-zA-Z0-9]*$"
        let inputP = NSPredicate(format:"SELF MATCHES %@", regex)
        return inputP.evaluate(with: self)
    }
    
    var isValidEmail: Bool {
        let emailRegEx = "(?:[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}" +
            "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" +
            "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[\\p{L}0-9](?:[a-" +
            "z0-9-]*[\\p{L}0-9])?\\.)+[\\p{L}0-9](?:[\\p{L}0-9-]*[\\p{L}0-9])?|\\[(?:(?:25[0-5" +
            "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" +
            "9][0-9]?|[\\p{L}0-9-]*[\\p{L}0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" +
        "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        let emailP = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailP.evaluate(with: self)
    }
    
    var isLuhn: Bool {
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
    
    var isValidCard: Bool {
        return count >= 13 && count <= 19 && isLuhn
    }
    
    func toDate(withFormat f: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ", timeZone: TimeZone? = nil) -> Date? {
        let df = DateFormatter()
        df.dateFormat = f
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = timeZone == nil ? TimeZone(abbreviation: "UTC") : timeZone
        return df.date(from: self)
    }
    
    func addPaddingForBase64Decoding() -> String {
        let remainder = self.count % 4
        guard remainder != 0 else { return self }
        let paddingLength =  4 - remainder
        let paddingChars = String(repeating: "=", count: paddingLength)
        return self + paddingChars
    }
    
    var decodedJWTToken: [String: Any]? {
        let components = self.split(separator: ".")
        if components.count < 1 { return nil }
        let segment = String(components[1]).padding(toLength: ((String(components[1]).count+3)/4)*4,
                                                              withPad: "=",
                                                              startingAt: 0)
        guard !segment.isEmpty, let data = Data(base64Encoded: segment) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else { return nil }
        return json
    }
    
}
