//
//  RulesFactory.swift
//
//
//  Created by Boris on 20. 5. 2025..
//

// RulesFactory.swift

import Foundation

/// Factory for creating various validation rules with parameters
public struct RulesFactory {
    public init() {}
}

// For convenience, add type-safe helpers
public extension RulesFactory {
    func createCardNumberRule() -> CardNumberRule {
        return CardNumberRule()
    }

    func createCardholderNameRule() -> CardholderNameRule {
        return CardholderNameRule()
    }

    func createCVVRule(cardNetwork: CardNetwork) -> CVVRule {
        return CVVRule(cardNetwork: cardNetwork)
    }

    func createExpiryDateRule() -> ExpiryDateRule {
        return ExpiryDateRule()
    }
}
