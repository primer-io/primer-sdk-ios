//
//  DateExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 10/3/21.
//

import Foundation

internal extension Date {
    
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
    
}
