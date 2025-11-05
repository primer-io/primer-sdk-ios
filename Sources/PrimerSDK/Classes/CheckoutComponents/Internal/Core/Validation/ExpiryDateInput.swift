//
//  ExpiryDateInput.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Input structure for expiry date validation
struct ExpiryDateInput {
    let month: String
    let year: String
}

/// Validation rule for expiry date inputs
class ExpiryDateRule: ValidationRule {

    func validate(_ input: ExpiryDateInput) -> ValidationResult {
        let month = input.month.trimmingCharacters(in: .whitespacesAndNewlines)
        let year = input.year.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if empty - use Android-matching error structure with automatic message resolution
        if month.isEmpty || year.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .expiryDate)
            return .invalid(error: error)
        }

        // Parse month and year - use Android-matching error structure with automatic message resolution
        guard let monthInt = Int(month), let yearInt = Int(year) else {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .expiryDate)
            return .invalid(error: error)
        }

        // Validate month range - use Android-matching error structure with automatic message resolution
        if monthInt < 1 || monthInt > 12 {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .expiryDate)
            return .invalid(error: error)
        }

        // Check if expired - use Android-matching error structure with automatic message resolution
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let currentMonth = Calendar.current.component(.month, from: Date())

        if yearInt < currentYear || (yearInt == currentYear && monthInt < currentMonth) {
            // Create specific expired card error
            let error = ValidationError(
                inputElementType: .expiryDate,
                errorId: "card_expired",
                fieldNameKey: "expiry_date_field",
                errorMessageKey: "form_error_card_expired",
                errorFormatKey: nil,
                code: "card-expired",
                message: "Card has expired"
            )
            return .invalid(error: error)
        }

        return .valid
    }
}
