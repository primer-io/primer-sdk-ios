//
//  ExampleConfig.swift
//  Debug App
//
//  Created by Claude on 27.6.25.
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//

import Foundation
import PrimerSDK

// MARK: - Example Configuration Model

struct ExampleConfig: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let paymentMethods: [String]
    let customization: CheckoutCustomization?
    
    enum CheckoutCustomization {
        case colorful
    }
}

// MARK: - Styling Examples

let stylingExamples: [ExampleConfig] = [
    ExampleConfig(
        name: "Colorful Theme",
        description: "Branded colors with gradients",
        paymentMethods: ["PAYMENT_CARD"],
        customization: .colorful
    )
]

// MARK: - Default Examples

let defaultExamples: [ExampleConfig] = [
    ExampleConfig(
        name: "Default CheckoutComponents",
        description: "Basic CheckoutComponents with surcharge display - shows all features",
        paymentMethods: ["PAYMENT_CARD", "APPLE_PAY"],
        customization: nil
    )
]

// MARK: - All Examples by Category

enum ExampleCategory: String, CaseIterable {
    case `default` = "Default Example"
    case styling = "Styling Variations"
    
    var examples: [ExampleConfig] {
        switch self {
        case .default:
            return defaultExamples
        case .styling:
            return stylingExamples
        }
    }
    
    var description: String {
        switch self {
        case .default:
            return "Basic CheckoutComponents without customization"
        case .styling:
            return "Various visual themes and customizations"
        }
    }
}
