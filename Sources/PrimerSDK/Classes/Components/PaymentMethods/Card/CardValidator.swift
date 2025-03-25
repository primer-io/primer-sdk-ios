//
//  CardValidator.swift
//  
//
//  Created by Boris on 24.3.25..
//


import Foundation

/// Protocol defining a validator for card inputs
protocol CardValidator {
    /// Validates a card number
    /// - Parameter cardNumber: The card number to validate
    /// - Returns: Validation error if invalid, nil if valid
    func validateCardNumber(_ cardNumber: String) -> ValidationError?
    
    /// Validates a card expiration date
    /// - Parameters:
    ///   - month: The expiration month to validate
    ///   - year: The expiration year to validate
    /// - Returns: Validation error if invalid, nil if valid
    func validateExpiration(month: String, year: String) -> ValidationError?
    
    /// Validates a CVV
    /// - Parameters:
    ///   - cvv: The CVV to validate
    ///   - cardNetwork: The card network type
    /// - Returns: Validation error if invalid, nil if valid
    func validateCvv(_ cvv: String, cardNetwork: CardNetwork) -> ValidationError?
    
    /// Validates a cardholder name
    /// - Parameter name: The cardholder name to validate
    /// - Returns: Validation error if invalid, nil if valid
    func validateCardholderName(_ name: String) -> ValidationError?
    
    /// Validates all card fields
    /// - Parameters:
    ///   - cardNumber: The card number
    ///   - expiryMonth: The expiration month
    ///   - expiryYear: The expiration year
    ///   - cvv: The CVV
    ///   - cardholderName: The cardholder name
    /// - Returns: List of validation errors, empty if all valid
    func validateCard(cardNumber: String,
                      expiryMonth: String,
                      expiryYear: String,
                      cvv: String,
                      cardholderName: String) -> [ValidationError]
}

/// Default implementation of card validation
class DefaultCardValidator: CardValidator {
    func validateCardNumber(_ cardNumber: String) -> ValidationError? {
        if cardNumber.isEmpty {
            return ValidationError(code: "invalid-card-number", message: "Card number is required")
        }
        
        let sanitized = cardNumber.replacingOccurrences(of: " ", with: "")
        if sanitized.count < 13 || sanitized.count > 19 {
            return ValidationError(code: "invalid-card-number", message: "Card number length is invalid")
        }
        
        if !isLuhnValid(sanitized) {
            return ValidationError(code: "invalid-card-number", message: "Card number is invalid")
        }
        
        let network = CardNetwork(cardNumber: sanitized)
        if network == .unknown {
            return ValidationError(code: "unsupported-card-type", message: "Card type is not supported")
        }
        
        return nil
    }
    
    func validateExpiration(month: String, year: String) -> ValidationError? {
        if month.isEmpty || year.isEmpty {
            return ValidationError(code: "invalid-expiry-date", message: "Expiry date is required")
        }
        
        guard let monthInt = Int(month), let yearInt = Int(year) else {
            return ValidationError(code: "invalid-expiry-date", message: "Expiry date must contain valid numbers")
        }
        
        if monthInt < 1 || monthInt > 12 {
            return ValidationError(code: "invalid-expiry-date", message: "Month must be between 1 and 12")
        }
        
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate) % 100
        let currentMonth = calendar.component(.month, from: currentDate)
        
        if yearInt < currentYear || (yearInt == currentYear && monthInt < currentMonth) {
            return ValidationError(code: "invalid-expiry-date", message: "Expiry date is in the past")
        }
        
        return nil
    }
    
    func validateCvv(_ cvv: String, cardNetwork: CardNetwork) -> ValidationError? {
        if cvv.isEmpty {
            return ValidationError(code: "invalid-cvv", message: "CVV is required")
        }
        
        let expectedLength = cardNetwork == .amex ? 4 : 3
        if cvv.count != expectedLength {
            return ValidationError(code: "invalid-cvv", message: "CVV must be \(expectedLength) digits")
        }
        
        if !cvv.allSatisfy({ $0.isNumber }) {
            return ValidationError(code: "invalid-cvv", message: "CVV must contain only digits")
        }
        
        return nil
    }
    
    func validateCardholderName(_ name: String) -> ValidationError? {
        if name.isEmpty {
            return ValidationError(code: "invalid-cardholder-name", message: "Cardholder name is required")
        }
        
        if name.count < 2 {
            return ValidationError(code: "invalid-cardholder-name", message: "Cardholder name is too short")
        }
        
        return nil
    }
    
    func validateCard(cardNumber: String, expiryMonth: String, expiryYear: String, cvv: String, cardholderName: String) -> [ValidationError] {
        var errors = [ValidationError]()
        
        if let error = validateCardNumber(cardNumber) {
            errors.append(error)
        }
        
        if let error = validateExpiration(month: expiryMonth, year: expiryYear) {
            errors.append(error)
        }
        
        let cardNetwork = CardNetwork(cardNumber: cardNumber.replacingOccurrences(of: " ", with: ""))
        if let error = validateCvv(cvv, cardNetwork: cardNetwork) {
            errors.append(error)
        }
        
        if let error = validateCardholderName(cardholderName) {
            errors.append(error)
        }
        
        return errors
    }
    
    // MARK: - Private Helpers
    
    private func isLuhnValid(_ number: String) -> Bool {
        let reversedDigits = number.reversed().compactMap { Int(String($0)) }
        var sum = 0
        
        for (index, digit) in reversedDigits.enumerated() {
            if index % 2 == 1 {
                let doubledValue = digit * 2
                sum += doubledValue > 9 ? doubledValue - 9 : doubledValue
            } else {
                sum += digit
            }
        }
        
        return sum % 10 == 0
    }
}
