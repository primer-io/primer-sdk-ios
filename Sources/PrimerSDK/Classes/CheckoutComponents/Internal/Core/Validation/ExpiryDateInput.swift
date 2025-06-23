//
//  ExpiryDateInput.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Input structure for expiry date validation
internal struct ExpiryDateInput {
    let month: String
    let year: String
}

/// Validation rule for expiry date inputs
internal class ExpiryDateRule: ValidationRule {

    func validate(_ input: ExpiryDateInput) -> ValidationResult {
        let month = input.month.trimmingCharacters(in: .whitespacesAndNewlines)
        let year = input.year.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if empty
        if month.isEmpty || year.isEmpty {
            return .invalid(code: "invalid-expiry-date", message: "Expiry date is required")
        }

        // Parse month and year
        guard let monthInt = Int(month), let yearInt = Int(year) else {
            return .invalid(code: "invalid-expiry-format", message: "Invalid expiry date format")
        }

        // Validate month range
        if monthInt < 1 || monthInt > 12 {
            return .invalid(code: "invalid-month", message: "Invalid month")
        }

        // Check if expired
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let currentMonth = Calendar.current.component(.month, from: Date())

        if yearInt < currentYear || (yearInt == currentYear && monthInt < currentMonth) {
            return .invalid(code: "card-expired", message: "Card has expired")
        }

        return .valid
    }
}
