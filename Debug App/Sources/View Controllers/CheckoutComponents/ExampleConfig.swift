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
    let customization: CheckoutCustomization?
    
    enum CheckoutCustomization {
        case colorful
        case stepByStep
        case dynamicLayout
        case runtimeCustomization
        case propertyReassignment
        case mixedComponents
        case customPaymentSelection
    }
}

// MARK: - Styling Examples

let stylingExamples: [ExampleConfig] = [
    ExampleConfig(
        name: "Single Field Customisation",
        description: "Customize only cardholder name field",
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

// MARK: - Architecture Examples

let architectureExamples: [ExampleConfig] = [
    ExampleConfig(
        name: "Step-by-Step Navigation",
        description: "Single input field with Previous/Next controls",
        paymentMethods: ["PAYMENT_CARD"],
        customization: .stepByStep
    ),
    ExampleConfig(
        name: "Mixed Components",
        description: "Combining default and custom styled fields",
        paymentMethods: ["PAYMENT_CARD"],
        customization: .mixedComponents
    )
]

// MARK: - Layout Examples

let layoutExamples: [ExampleConfig] = [
    ExampleConfig(
        name: "Dynamic Layouts",
        description: "Switch between vertical, horizontal, grid, and compact layouts",
        paymentMethods: ["PAYMENT_CARD"],
        customization: .dynamicLayout
    ),
    ExampleConfig(
        name: "Custom Payment Selection Screen",
        description: "Complete UI customization with gradient backgrounds and animations",
        paymentMethods: ["PAYMENT_CARD", "PAYPAL", "APPLE_PAY"],
        customization: .customPaymentSelection
    )
]

// MARK: - Interactive Examples

let interactiveExamples: [ExampleConfig] = [
    ExampleConfig(
        name: "Property Reassignment",
        description: "Change component properties dynamically at runtime",
        paymentMethods: ["PAYMENT_CARD"],
        customization: .propertyReassignment
    ),
    ExampleConfig(
        name: "Conditional Customization",
        description: "Components adapt based on card type and validation state",
        paymentMethods: ["PAYMENT_CARD"],
        customization: .runtimeCustomization
    )
]

// MARK: - All Examples by Category

enum ExampleCategory: String, CaseIterable {
    case `default` = "Default Example"
    case styling = "Styling Variations"
    case architecture = "Architecture Patterns"
    case layouts = "Layout Variations"
    case interactive = "Interactive Features"
    
    var examples: [ExampleConfig] {
        switch self {
        case .default:
            return defaultExamples
        case .styling:
            return stylingExamples
        case .architecture:
            return architectureExamples
        case .layouts:
            return layoutExamples
        case .interactive:
            return interactiveExamples
        }
    }
    
    var description: String {
        switch self {
        case .default:
            return "Basic CheckoutComponents without customization"
        case .styling:
            return "Various visual themes and customizations"
        case .architecture:
            return "Component composition and structure variations"
        case .layouts:
            return "Different ways to arrange form fields"
        case .interactive:
            return "Runtime behavior and conditional customization"
        }
    }
}
