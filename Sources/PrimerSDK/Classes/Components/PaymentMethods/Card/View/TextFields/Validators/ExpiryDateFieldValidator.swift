//
//  ExpiryDateFieldValidator.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

import Foundation

public class ExpiryDateFieldValidator: FieldValidator {
    private let validationService: ValidationService

    public init(validationService: ValidationService) {
        self.validationService = validationService
    }

    public func validateWhileTyping(_ input: String) -> ValidationResult {
        if input.isEmpty {
            return .valid // Don't show errors for empty field during typing
        }

        // Extract month and year
        let parts = input.components(separatedBy: "/")
        if parts.count < 2 || parts[1].count < 2 {
            return .valid // Still typing, don't validate yet
        }

        let month = parts[0]
        let year = parts[1]

        // Basic validation for immediate feedback
        if month.count == 2 && year.count == 2 &&
           month.allSatisfy({ $0.isNumber }) && year.allSatisfy({ $0.isNumber }) &&
           (Int(month) ?? 0) >= 1 && (Int(month) ?? 0) <= 12 {
            // Do a minimal check for expired dates
            let currentYear = Calendar.current.component(.year, from: Date()) % 100
            let currentMonth = Calendar.current.component(.month, from: Date())

            if let monthInt = Int(month), let yearInt = Int(year) {
                if yearInt < currentYear || (yearInt == currentYear && monthInt < currentMonth) {
                    return .invalid(code: "expired-date", message: "Card has expired")
                }
            }

            return .valid
        }

        return .valid // Continue to allow typing
    }

    public func validateOnCommit(_ input: String) -> ValidationResult {
        if input.isEmpty {
            return .invalid(code: "invalid-expiry-date", message: "Expiry date is required")
        }

        // Create input object for validation service
        let parts = input.components(separatedBy: "/")
        guard parts.count == 2 else {
            return .invalid(code: "invalid-expiry-format", message: "Please enter date as MM/YY")
        }

        // Full validation on blur
        return validationService.validateExpiry(month: parts[0], year: parts[1])
    }
}
