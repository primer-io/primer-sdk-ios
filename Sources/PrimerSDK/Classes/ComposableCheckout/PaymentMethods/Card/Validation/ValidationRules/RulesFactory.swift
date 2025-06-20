//
//  RulesFactory.swift
//
//
//  Created by Boris on 20. 5. 2025..
//

// RulesFactory.swift

import Foundation

/// Factory for creating various validation rules with parameters
public struct RulesFactory: SynchronousFactory {
    public typealias Product = Any

    // Define parameter types
    public enum RuleType {
        case cardNumber
        case cardholderName
        case cvv(cardNetwork: CardNetwork)
        case expiryDate
    }

    public typealias Params = RuleType

    public init() {}

    public func createSync(with params: RuleType) throws -> Any {
        switch params {
        case .cardNumber:
            return CardNumberRule()
        case .cardholderName:
            return CardholderNameRule()
        case .cvv(let cardNetwork):
            return CVVRule(cardNetwork: cardNetwork)
        case .expiryDate:
            return ExpiryDateRule()
        }
    }
}

// For convenience, add type-safe helpers
public extension RulesFactory {
    func createCardNumberRule() -> CardNumberRule {
        guard let rule = try? createSync(with: .cardNumber) as? CardNumberRule else {
            return CardNumberRule()
        }
        return rule
    }

    func createCardholderNameRule() -> CardholderNameRule {
        guard let rule = try? createSync(with: .cardholderName) as? CardholderNameRule else {
            return CardholderNameRule()
        }
        return rule
    }

    func createCVVRule(cardNetwork: CardNetwork) -> CVVRule {
        guard let rule = try? createSync(with: .cvv(cardNetwork: cardNetwork)) as? CVVRule else {
            return CVVRule(cardNetwork: cardNetwork)
        }
        return rule
    }

    func createExpiryDateRule() -> ExpiryDateRule {
        guard let rule = try? createSync(with: .expiryDate) as? ExpiryDateRule else {
            return ExpiryDateRule()
        }
        return rule
    }
}
