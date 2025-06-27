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
    let sessionType: SessionType
    let paymentMethods: [String]
    let customization: CheckoutCustomization?
    
    enum SessionType {
        case cardOnly
        case cardAndApplePay
        case fullMethods
        case custom(ClientSessionRequestBody.PaymentMethod)
    }
    
    enum CheckoutCustomization {
        case compact
        case expanded
        case inline
        case grid
        case corporate
        case modern
        case colorful
        case dark
        case liveState
        case validation
        case coBadged
        case modifierChains
        case customScreen
        case animated
    }
}

// MARK: - Session Creation Extension

extension ExampleConfig {
    func createSession() -> ClientSessionRequestBody {
        switch sessionType {
        case .cardOnly:
            return MerchantMockDataManager.getClientSession(sessionType: .cardOnly)
        case .cardAndApplePay:
            return MerchantMockDataManager.getClientSession(sessionType: .cardAndApplePay)
        case .fullMethods:
            return MerchantMockDataManager.getClientSession(sessionType: .generic)
        case .custom(let paymentMethod):
            return MerchantMockDataManager.getClientSession(sessionType: .custom(paymentMethod))
        }
    }
}

// MARK: - Layout Examples

let layoutExamples: [ExampleConfig] = [
    ExampleConfig(
        name: "Compact Layout",
        description: "Horizontal fields with tight spacing",
        sessionType: .cardOnly,
        paymentMethods: ["PAYMENT_CARD"],
        customization: .compact
    ),
    ExampleConfig(
        name: "Expanded Layout", 
        description: "Vertical fields with generous spacing",
        sessionType: .cardAndApplePay,
        paymentMethods: ["PAYMENT_CARD", "APPLE_PAY"],
        customization: .expanded
    ),
    ExampleConfig(
        name: "Inline Layout",
        description: "Embedded seamlessly in content",
        sessionType: .fullMethods,
        paymentMethods: ["PAYMENT_CARD", "APPLE_PAY", "PAYPAL", "GOOGLE_PAY"],
        customization: .inline
    ),
    ExampleConfig(
        name: "Grid Layout",
        description: "Card details in organized grid",
        sessionType: .cardOnly,
        paymentMethods: ["PAYMENT_CARD"],
        customization: .grid
    )
]

// MARK: - Styling Examples

let stylingExamples: [ExampleConfig] = [
    ExampleConfig(
        name: "Corporate Theme",
        description: "Professional blue and gray styling",
        sessionType: .cardOnly,
        paymentMethods: ["PAYMENT_CARD"],
        customization: .corporate
    ),
    ExampleConfig(
        name: "Modern Theme",
        description: "Clean white with subtle shadows",
        sessionType: .cardOnly,
        paymentMethods: ["PAYMENT_CARD"],
        customization: .modern
    ),
    ExampleConfig(
        name: "Colorful Theme",
        description: "Branded colors with gradients",
        sessionType: .cardOnly,
        paymentMethods: ["PAYMENT_CARD"],
        customization: .colorful
    ),
    ExampleConfig(
        name: "Dark Theme",
        description: "Full dark mode implementation",
        sessionType: .cardOnly,
        paymentMethods: ["PAYMENT_CARD"],
        customization: .dark
    )
]

// MARK: - Interactive Examples

let interactiveExamples: [ExampleConfig] = [
    ExampleConfig(
        name: "Live State Demo",
        description: "Real-time state updates and debugging",
        sessionType: .cardOnly,
        paymentMethods: ["PAYMENT_CARD"],
        customization: .liveState
    ),
    ExampleConfig(
        name: "Validation Showcase",
        description: "Error states and validation feedback",
        sessionType: .cardOnly,
        paymentMethods: ["PAYMENT_CARD"],
        customization: .validation
    ),
    ExampleConfig(
        name: "Co-badged Cards",
        description: "Multiple network selection demo",
        sessionType: .cardOnly,
        paymentMethods: ["PAYMENT_CARD"],
        customization: .coBadged
    )
]

// MARK: - Advanced Examples

let advancedExamples: [ExampleConfig] = [
    ExampleConfig(
        name: "PrimerModifier Chains",
        description: "Complex styling combinations",
        sessionType: .cardOnly,
        paymentMethods: ["PAYMENT_CARD"],
        customization: .modifierChains
    ),
    ExampleConfig(
        name: "Custom Screen Layout",
        description: "Completely custom form layouts",
        sessionType: .cardOnly,
        paymentMethods: ["PAYMENT_CARD"],
        customization: .customScreen
    ),
    ExampleConfig(
        name: "Animation Playground",
        description: "Various animation styles",
        sessionType: .cardOnly,
        paymentMethods: ["PAYMENT_CARD"],
        customization: .animated
    )
]

// MARK: - Default Examples

let defaultExamples: [ExampleConfig] = [
    ExampleConfig(
        name: "Default CheckoutComponents",
        description: "Basic CheckoutComponents without customization - shows all payment methods",
        sessionType: .fullMethods,
        paymentMethods: ["PAYMENT_CARD", "APPLE_PAY", "PAYPAL", "GOOGLE_PAY"],
        customization: nil
    )
]

// MARK: - All Examples by Category

enum ExampleCategory: String, CaseIterable {
    case `default` = "Default Example"
    case layouts = "Layout Configurations"
    case styling = "Styling Variations"
    case interactive = "Interactive Features"
    case advanced = "Advanced Customization"
    
    var examples: [ExampleConfig] {
        switch self {
        case .default:
            return defaultExamples
        case .layouts:
            return layoutExamples
        case .styling:
            return stylingExamples
        case .interactive:
            return interactiveExamples
        case .advanced:
            return advancedExamples
        }
    }
    
    var description: String {
        switch self {
        case .default:
            return "Basic CheckoutComponents without customization"
        case .layouts:
            return "Different ways to arrange CheckoutComponents"
        case .styling:
            return "Various visual themes and customizations"
        case .interactive:
            return "Dynamic behaviors and real-time interactions"
        case .advanced:
            return "Complex styling and custom implementations"
        }
    }
}