//
//  FieldFormatter.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

public protocol FieldFormatter {
    /// Formats raw input into display text
    func format(_ input: String) -> String
}
