//
//  CVVRule.swift
//
//
//  Created by Boris on 26.3.25..
//

import Foundation

/// Validates a CVV based on the card network
public struct CVVRule: ValidationRule {
    private let cardNetwork: CardNetwork

    public init(cardNetwork: CardNetwork) {
        self.cardNetwork = cardNetwork
    }

    public func validate(_ cvv: String) -> ValidationResult {
        // Check if empty
        if cvv.isEmpty {
            return .invalid(
                code: "invalid-cvv",
                message: "CVV is required"
            )
        }

        // Check for numeric characters
        if !cvv.allSatisfy({ $0.isNumber }) {
            return .invalid(
                code: "invalid-cvv-format",
                message: "CVV must contain only digits"
            )
        }

        // Check length based on card type
        let expectedLength = cardNetwork.validation?.code.length ?? 3
        if cvv.count != expectedLength {
            return .invalid(
                code: "invalid-cvv-length",
                message: "CVV must be \(expectedLength) digits"
            )
        }

        return .valid
    }
}
