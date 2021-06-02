//
//  String+Helpers.swift
//  PrimerCoreKit
//
//  Created by Evangelos Pittas on 26/5/21.
//

import Foundation

internal extension String {

    var withoutWhiteSpace: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "")
    }
    
    var isNumeric: Bool {
        guard !self.isEmpty else { return false }
        let nums: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        return Set(self).isSubset(of: nums)
    }
    
    var isValidExpiryDateCharacter: Bool {
        guard !self.isEmpty else { return true }
        let allowedCharacters: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "/"]
        let isValid = Set(self).isSubset(of: allowedCharacters)
        return isValid
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
    
    func separate(every: Int, with separator: String) -> String {
        return String(stride(from: 0, to: Array(self).count, by: every).map {
            Array(Array(self)[$0..<min($0 + every, Array(self).count)])
        }.joined(separator: separator))
    }
    
    func toDate(withFormat f: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ", timeZone: TimeZone? = nil) -> Date? {
        let df = DateFormatter()
        df.dateFormat = f
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = timeZone == nil ? TimeZone(abbreviation: "UTC") : timeZone
        return df.date(from: self)
    }

}

public extension String {
    
    var isValidCardnumber: Bool {
        let cleanStr = withoutWhiteSpace
        return cleanStr.isNumeric && cleanStr.count >= 13 && cleanStr.count <= 19 && cleanStr.isValidLuhn
    }
    
}
