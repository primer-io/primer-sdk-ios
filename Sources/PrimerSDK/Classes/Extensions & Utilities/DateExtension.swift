//
//  DateExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 10/3/21.
//

import Foundation

func +(_ lhs: DateComponents, _ rhs: DateComponents) -> DateComponents {
    return combineComponents(lhs, rhs)
}

func -(_ lhs: DateComponents, _ rhs: DateComponents) -> DateComponents {
    return combineComponents(lhs, rhs, multiplier: -1)
}

func combineComponents(_ lhs: DateComponents, _ rhs: DateComponents, multiplier: Int = 1) -> DateComponents {
    var result = DateComponents()
    result.nanosecond = (lhs.nanosecond ?? 0) + (rhs.nanosecond ?? 0) * multiplier
    result.second     = (lhs.second     ?? 0) + (rhs.second     ?? 0) * multiplier
    result.minute     = (lhs.minute     ?? 0) + (rhs.minute     ?? 0) * multiplier
    result.hour       = (lhs.hour       ?? 0) + (rhs.hour       ?? 0) * multiplier
    result.day        = (lhs.day        ?? 0) + (rhs.day        ?? 0) * multiplier
    result.weekOfYear = (lhs.weekOfYear ?? 0) + (rhs.weekOfYear ?? 0) * multiplier
    result.month      = (lhs.month      ?? 0) + (rhs.month      ?? 0) * multiplier
    result.year       = (lhs.year       ?? 0) + (rhs.year       ?? 0) * multiplier
    return result
}

prefix func -(components: DateComponents) -> DateComponents {
    var result = DateComponents()
    if components.nanosecond != nil { result.nanosecond = -components.nanosecond! }
    if components.second     != nil { result.second     = -components.second! }
    if components.minute     != nil { result.minute     = -components.minute! }
    if components.hour       != nil { result.hour       = -components.hour! }
    if components.day        != nil { result.day        = -components.day! }
    if components.weekOfYear != nil { result.weekOfYear = -components.weekOfYear! }
    if components.month      != nil { result.month      = -components.month! }
    if components.year       != nil { result.year       = -components.year! }
    return result
}

func +(_ lhs: Date, _ rhs: DateComponents) -> Date {
    return Calendar.current.date(byAdding: rhs, to: lhs)!
}

func +(_ lhs: DateComponents, _ rhs: Date) -> Date {
    return rhs + lhs
}

func -(_ lhs: Date, _ rhs: DateComponents) -> Date {
    return lhs + (-rhs)
}

func -(_ lhs: Date, _ rhs: Date) -> DateComponents {
  return Calendar.current.dateComponents(
    [.year, .month, .weekOfYear, .day, .hour, .minute, .second, .nanosecond],
    from: rhs,
    to: lhs)
}

extension Date {

    init(year: Int,
         month: Int,
         day: Int,
         hour: Int = 0,
         minute: Int = 0,
         second: Int = 0,
         timeZone: TimeZone = TimeZone(abbreviation: "UTC")!) {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.timeZone = timeZone
        self = Calendar.current.date(from: components)!
    }

    init(dateString: String, dateFormat: String = "yyyy-MM-dd HH:mm:ss") {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        self = formatter.date(from: dateString)!
    }

    var `description`: String {
        get {
            let PREFERRED_LOCALE = "en_US" // Use whatever locale you prefer!
            return self.description(with: Locale(identifier: PREFERRED_LOCALE))
        }
    }

    func toString(withFormat f: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ", timeZone: TimeZone? = nil, calendar: Calendar? = nil) -> String {
        let df = DateFormatter()
        df.dateFormat = f
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = timeZone == nil ? TimeZone.current : timeZone!
        df.calendar = calendar == nil ? Calendar(identifier: .gregorian) : calendar!
        return df.string(from: self)
    }

    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var startOfMonth: Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: self)
        return  calendar.date(from: components)!
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar(identifier: .gregorian).date(byAdding: components, to: startOfMonth)!
    }
}

extension DateComponents {

  var fromNow: Date {
    return Calendar.current.date(byAdding: self, to: Date())!
  }

  var ago: Date {
    return Calendar.current.date(byAdding: -self, to: Date())!
  }

}
