//
//  Date.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public extension Date {

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var isValidExpiryDate: Bool {
        Date() < endOfMonth
    }

    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: startOfDay)
        return Calendar.current.date(from: components)!
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth)!
    }

    var yearComponentAsString: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        if let year = components.year {
            return "\(year)"
        }
        return ""
    }

    // swiftlint:disable identifier_name
    func toString(withFormat f: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ", timeZone: TimeZone? = nil, calendar: Calendar? = nil) -> String {
        let df = DateFormatter()
        df.dateFormat = f
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = timeZone == nil ? TimeZone.current : timeZone!
        df.calendar = calendar == nil ? Calendar(identifier: .gregorian) : calendar!
        return df.string(from: self)
    }
    // swiftlint:enable identifier_name

    var millisecondsSince1970: Int {
        Int((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}
