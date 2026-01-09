//
//  String.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public extension String {
    static var uuid: String { UUID().uuidString }
}

public extension String {
	func jsonObject<T>() throws -> T {
        do {
            let object = try JSONSerialization.jsonObject(with: Data(utf8), options: [])
            if let typedObject = object as? T {
                return typedObject
            } else {
                throw CastError.typeMismatch(value: object, type: T.self)
            }
        }
	}
    
    func unsafeData() -> Data { data(using: .utf8)! }
    
    var withoutWhiteSpace: String {
        self.replacingOccurrences(of: " ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isNumeric: Bool {
        guard !self.isEmpty else { return false }
        let nums: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        return Set(self).isSubset(of: nums)
    }

    var withoutNonNumericCharacters: String {
        withoutWhiteSpace.filter("0123456789".contains)
    }

    var isValidNonDecimalString: Bool {
        if isEmpty { return false }
        return rangeOfCharacter(from: .decimalDigits) == nil
    }

    var base64RFC4648Format: Self {
        self.replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    func toDate(withFormat format: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                timeZone: TimeZone? = nil) -> Date? {
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
        String(stride(from: 0, to: Array(self).count, by: every).map {
            Array(Array(self)[$0..<min($0 + every, Array(self).count)])
        }.joined(separator: separator))
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

    var isValidOTP: Bool {
        let pattern = "^\\d{6}$"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let matches = regex?.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
        return matches?.count ?? 0 > 0
    }

    /// Normalizes a year string to 4-digit format
    /// - Returns: A 4-digit year string, or nil if the input is not a valid 2-digit or 4-digit year
    /// - Note: 2-digit years (e.g., "30") are converted using current century (e.g., "2030")
    ///         4-digit years (e.g., "2030") are returned as-is
    ///         Invalid inputs return nil
    func normalizedFourDigitYear() -> String? {
        guard self.allSatisfy(\.isNumber) else { return nil }

        switch self.count {
        case 4:
            return self
        case 2:
            // Convert 2-digit year to 4-digit using current century
            let currentYear = Calendar.current.component(.year, from: Date())
            let century = String(currentYear).prefix(2)
            return "\(century)\(self)"
        default:
            return nil
        }
    }
}
