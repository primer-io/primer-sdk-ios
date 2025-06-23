//
//  AdditionalValidationRules.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Validation rule for phone numbers.
internal class PhoneNumberRule: ValidationRule {

    func validate(_ value: String) -> ValidationResult {
        let cleanedValue = value.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "+", with: "")

        if cleanedValue.isEmpty {
            return .invalid(code: "invalid-phone-number", message: "Phone number is required")
        }

        // Check if all digits after cleaning
        if !cleanedValue.allSatisfy({ $0.isNumber }) {
            return .invalid(code: "invalid-phone-number-format", message: "Phone number contains invalid characters")
        }

        // Check length (between 7 and 15 digits for international)
        if cleanedValue.count < 7 || cleanedValue.count > 15 {
            return .invalid(code: "invalid-phone-number-length", message: "Invalid phone number length")
        }

        return .valid
    }
}

/// Validation rule for email addresses.
internal class EmailRule: ValidationRule {

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty {
            return .invalid(code: "invalid-email", message: "Email is required")
        }

        // Basic email validation pattern
        let emailPattern = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        if trimmedValue.range(of: emailPattern, options: .regularExpression) == nil {
            return .invalid(code: "invalid-email-format", message: "Invalid email format")
        }

        return .valid
    }
}

/// Validation rule for retail outlets.
internal class RetailOutletRule: ValidationRule {

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty {
            return .invalid(code: "invalid-retail-outlet", message: "Retail outlet is required")
        }

        return .valid
    }
}

/// Validation rule for OTP codes.
internal class OTPCodeRule: ValidationRule {

    private let expectedLength: Int

    init(expectedLength: Int = 6) {
        self.expectedLength = expectedLength
    }

    func validate(_ value: String) -> ValidationResult {
        if value.isEmpty {
            return .invalid(code: "invalid-otp-code", message: "OTP code is required")
        }

        // Check if all digits
        if !value.allSatisfy({ $0.isNumber }) {
            return .invalid(code: "invalid-otp-code-format", message: "OTP must contain only digits")
        }

        // Check length
        if value.count != expectedLength {
            return .invalid(code: "invalid-otp-code-length", message: "OTP must be \(expectedLength) digits")
        }

        return .valid
    }
}

/// Validation rule for birth dates.
internal class BirthDateRule: ValidationRule {

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty {
            return .invalid(code: "invalid-birth-date", message: "Birth date is required")
        }

        // Try to parse date (DD/MM/YYYY format)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        guard let birthDate = dateFormatter.date(from: trimmedValue) else {
            return .invalid(code: "invalid-birth-date-format", message: "Invalid date format (DD/MM/YYYY)")
        }

        // Check if date is in the past
        if birthDate > Date() {
            return .invalid(code: "invalid-birth-date-future", message: "Birth date cannot be in the future")
        }

        // Check minimum age (e.g., 18 years)
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        if let age = ageComponents.year, age < 18 {
            return .invalid(code: "invalid-birth-date-age", message: "Must be at least 18 years old")
        }

        return .valid
    }
}
