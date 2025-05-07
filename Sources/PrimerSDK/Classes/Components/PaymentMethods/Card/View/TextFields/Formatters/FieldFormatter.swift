//
//  FieldFormatter.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

public protocol FieldFormatter {
    /// Formats raw input into display text
    func format(_ input: String) -> String

    /// Swap in a new cardNetwork (mutating so you can call it on a `var formatter`)
    mutating func update(cardNetwork: CardNetwork)
}

public extension FieldFormatter {
    /// Default no-op so CVVFormatter, NameFormatter, etc don’t need to implement it.
    mutating func update(cardNetwork: CardNetwork) { }
}
