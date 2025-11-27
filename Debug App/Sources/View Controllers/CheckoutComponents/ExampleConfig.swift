//
//  ExampleConfig.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerSDK

// MARK: - Example Configuration Model

struct ExampleConfig: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let paymentMethods: [String]
}

// MARK: - Default Examples

let defaultExamples: [ExampleConfig] = [
    ExampleConfig(
        name: "Default CheckoutComponents",
        description: "Basic CheckoutComponents with surcharge display - shows all features",
        paymentMethods: ["PAYMENT_CARD", "APPLE_PAY"]
    )
]

// MARK: - Example Category

enum ExampleCategory: String, CaseIterable {
    case `default` = "Default Example"

    var examples: [ExampleConfig] {
        switch self {
        case .default:
            return defaultExamples
        }
    }

    var description: String {
        switch self {
        case .default:
            return "Basic CheckoutComponents without customization"
        }
    }
}
