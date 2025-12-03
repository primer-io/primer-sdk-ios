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
    let isCustom: Bool
}

// MARK: - All Examples

let allExamples: [ExampleConfig] = [
    ExampleConfig(
        name: "Default Checkout",
        description: "Standard CheckoutComponents with SDK-provided UI",
        paymentMethods: ["PAYMENT_CARD", "APPLE_PAY"],
        isCustom: false
    ),
    ExampleConfig(
        name: "Custom Payment Selection",
        description: "Fully custom payment screen with merchant-controlled layout, product details, and payment method display",
        paymentMethods: ["PAYMENT_CARD", "APPLE_PAY", "PAYPAL"],
        isCustom: true
    )
]
