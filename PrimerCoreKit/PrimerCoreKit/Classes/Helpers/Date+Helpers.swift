//
//  Date+Helpers.swift
//  PrimerCoreKit
//
//  Created by Evangelos Pittas on 2/6/21.
//

import Foundation

internal extension Date {
    
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
    
    var isValidExpiryDate: Bool {
        return endOfMonth.isInTheFuture == true
    }
    
    var isInTheFuture: Bool {
        return self > Date()
    }
    
}
