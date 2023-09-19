//
//  DateExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 10/3/21.
//



import Foundation

internal extension Date {
    
    var oneYearLater: Date {
        let dateComponents = Calendar.current.dateComponents([
            .second,
            .minute,
            .hour,
            .day,
            .month,
            .year
        ], from: self)
        
        var oneYearLaterDateComponents = DateComponents()
        oneYearLaterDateComponents.second = dateComponents.second!
        oneYearLaterDateComponents.minute = dateComponents.minute!
        oneYearLaterDateComponents.hour = dateComponents.hour!
        oneYearLaterDateComponents.day = dateComponents.day!
        oneYearLaterDateComponents.month = dateComponents.month!
        oneYearLaterDateComponents.year = dateComponents.year! + 1
        
        return Calendar.current.date(from: oneYearLaterDateComponents)!
    }
    
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
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
    
    var isValidExpiryDate: Bool {
        let oneYearLaterEndOfMonthDate = self.oneYearLater.endOfMonth
        let now = Date()
        return now < oneYearLaterEndOfMonthDate
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
    
    init(milliseconds: Int) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}


