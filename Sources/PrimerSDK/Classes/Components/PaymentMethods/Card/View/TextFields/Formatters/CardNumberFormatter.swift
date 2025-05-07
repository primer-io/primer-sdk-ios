//
//  CardNumberFormatter.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

import Foundation

public struct CardNumberFormatter: FieldFormatter {
    /// We keep this `var` so we can swap in a new network at runtime.
    private var cardNetwork: CardNetwork

    /// Default to `.unknown`
    public init(cardNetwork: CardNetwork = .unknown) {
        self.cardNetwork = cardNetwork
    }

    /// We are calling this whenever we detect a new BIN/network
    public mutating func update(cardNetwork: CardNetwork) {
        self.cardNetwork = cardNetwork
    }

    public func format(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }

        // Get maximum allowed length for this card network
        let maxLength = cardNetwork.validation?.lengths.max() ?? 19

        // Truncate to max length
        let truncatedDigits = String(digits.prefix(maxLength))

        // Use the network's gap pattern if known, or fallback.
        let gaps = cardNetwork.validation?.gaps ?? [4, 8, 12]

        var result = ""

        // Format with spaces at gap positions
        for (index, char) in truncatedDigits.enumerated() {
            result.append(char)
            // Add a space after positions defined in gaps (1-based, so check index+1)
            if gaps.contains(index + 1) && index < truncatedDigits.count - 1 {
                result += " "
            }
        }

        return result
    }
}
