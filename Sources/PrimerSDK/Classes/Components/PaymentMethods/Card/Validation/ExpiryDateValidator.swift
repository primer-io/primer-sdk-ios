//
//  ExpiryDateValidator.swift
//  
//
//  Created by Boris on 27.3.25..
//

import Foundation

class ExpiryDateValidator: BaseInputFieldValidator<String> {
    var onMonthChange: ((String) -> Void)?
    var onYearChange: ((String) -> Void)?
    
    override func validateWhileTyping(_ input: String) -> ValidationResult {
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
        
        // Notify about parts changes
        onMonthChange?(month)
        onYearChange?(year)
        
        // Basic validation for immediate feedback
        if month.count == 2 && year.count == 2 &&
           month.isNumeric && year.isNumeric &&
           (Int(month) ?? 0) >= 1 && (Int(month) ?? 0) <= 12 {
            // Do a minimal check for expired dates
            let currentYear = Calendar.current.component(.year, from: Date()) % 100
            let currentMonth = Calendar.current.component(.month, from: Date())
            
            if let monthInt = Int(month), let yearInt = Int(year) {
                if yearInt < currentYear || (yearInt == currentYear && monthInt < currentMonth) {
                    return .invalid(code: "expired-date", message: "Date is expired")
                }
            }
            
            return .valid
        }
        
        return .invalid(code: "invalid-expiry-format", message: "Date format should be MM/YY")
    }
    
    override func validateOnBlur(_ input: String) -> ValidationResult {
        // Create input object for validation service
        guard let expiryInput = ExpiryDateInput(formattedDate: input) else {
            return .invalid(code: "invalid-expiry-format", message: "Please enter date as MM/YY")
        }
        
        // Full validation on blur
        return validationService.validateExpiry(
            month: expiryInput.month,
            year: expiryInput.year
        )
    }
}
