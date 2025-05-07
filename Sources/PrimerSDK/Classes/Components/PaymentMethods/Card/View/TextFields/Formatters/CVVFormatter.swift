//
//  CVVFormatter.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

import Foundation

public struct CVVFormatter: FieldFormatter {
    /// We keep this `var` so we can swap in a new network at runtime.
    private var cardNetwork: CardNetwork

    /// Default to `.unknown` which uses 3 digits
    public init(cardNetwork: CardNetwork = .unknown) {
        self.cardNetwork = cardNetwork
    }

    /// Update the card network when detected
    public mutating func update(cardNetwork: CardNetwork) {
        self.cardNetwork = cardNetwork
    }

    public func format(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }

        // Get maximum allowed length for this card network
        let maxLength = cardNetwork.validation?.code.length ?? 3

        // Truncate to max length
        let truncatedDigits = String(digits.prefix(maxLength))

        return truncatedDigits
    }
}
