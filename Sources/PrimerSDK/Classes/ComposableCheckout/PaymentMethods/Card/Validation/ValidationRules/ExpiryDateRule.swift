//
//  ExpiryDateRule.swift
//
//
//  Created by Boris on 26.3.25..
//

import Foundation

/// Validates a card expiry date to ensure it's in the future
public struct ExpiryDateRule: ValidationRule {
    public init() {}

    public func validate(_ input: ExpiryDateInput) -> ValidationResult {
        // Validate month format and range
        guard let monthInt = Int(input.month), (1...12).contains(monthInt) else {
            return .invalid(
                code: "invalid-expiry-month",
                message: "Month must be between 1 and 12"
            )
        }

        // Validate year format
        guard let yearInt = Int(input.year) else {
            return .invalid(
                code: "invalid-expiry-year",
                message: "Year must be a valid number"
            )
        }

        // Check if expired
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate) % 100
        let currentMonth = calendar.component(.month, from: currentDate)

        if yearInt < currentYear || (yearInt == currentYear && monthInt < currentMonth) {
            return .invalid(
                code: "expired-date",
                message: "Expiry date has passed"
            )
        }

        return .valid
    }
}

/// Input structure for expiry date validation
public struct ExpiryDateInput {
    public let month: String
    public let year: String

    public init(month: String, year: String) {
        self.month = month
        self.year = year
    }

    public init?(formattedDate: String) {
        let components = formattedDate.components(separatedBy: "/")
        guard components.count == 2 else { return nil }
        
        let month = components[0]
        let year = components[1]
        
        // Validate format - month should be 1-2 digits, year should be 2 digits
        guard month.count >= 1 && month.count <= 2,
              year.count == 2,
              month.allSatisfy({ $0.isNumber }),
              year.allSatisfy({ $0.isNumber }) else {
            return nil
        }
        
        self.month = month
        self.year = year
    }
}
