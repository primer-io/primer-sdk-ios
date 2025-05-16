//
//  CardNumberRule.swift
//
//
//  Created by Boris on 26.3.25..
//

/// Validates a credit card number using the Luhn algorithm
public struct CardNumberRule: ValidationRule {
    public init() {}

    public func validate(_ cardNumber: String) -> ValidationResult {
        // Skip validation for empty values (handled by RequiredFieldRule)
        if cardNumber.isEmpty {
            return .invalid(
                code: "invalid-card-number",
                message: "Card number is required"
            )
        }

        let sanitized = cardNumber.replacingOccurrences(of: " ", with: "")

        // Check length
        if sanitized.count < 13 || sanitized.count > 19 {
            return .invalid(
                code: "invalid-card-number-length",
                message: "Card number length is invalid"
            )
        }

        // Check Luhn algorithm
        if !isLuhnValid(sanitized) {
            return .invalid(
                code: "invalid-card-number",
                message: "Card number is invalid"
            )
        }

        // Check card network
        let network = CardNetwork(cardNumber: sanitized)
        if network == .unknown {
            return .invalid(
                code: "unsupported-card-type",
                message: "Card type is not supported"
            )
        }

        return .valid
    }

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
