import SwiftUI

@available(iOS 15.0, *)
struct PaymentMethodDisplayModel: Identifiable, Equatable {
    let id: String
    let name: String
    let iconName: String?           // SF Symbol or asset name
    let backgroundColor: Color?     // From payment method config or nil for default
    let textColor: Color           // White for dark backgrounds, black for light
    let borderColor: Color?        // Optional border color
    let isEnabled: Bool
    let accessibilityLabel: String

    // Factory methods for common payment methods
    static func applePay(isEnabled: Bool = true) -> PaymentMethodDisplayModel {
        PaymentMethodDisplayModel(
            id: "apple_pay",
            name: "Apple Pay",
            iconName: "applelogo",
            backgroundColor: .black,
            textColor: .white,
            borderColor: nil,
            isEnabled: isEnabled,
            accessibilityLabel: "Pay with Apple Pay"
        )
    }

    static func payPal(isEnabled: Bool = true) -> PaymentMethodDisplayModel {
        PaymentMethodDisplayModel(
            id: "paypal",
            name: "PayPal",
            iconName: "paypal_logo", // Custom asset
            backgroundColor: Color(red: 1.0, green: 0.78, blue: 0.0), // PayPal yellow
            textColor: .black,
            borderColor: nil,
            isEnabled: isEnabled,
            accessibilityLabel: "Pay with PayPal"
        )
    }

    static func card(isEnabled: Bool = true) -> PaymentMethodDisplayModel {
        PaymentMethodDisplayModel(
            id: "payment_card",
            name: "Pay with card",
            iconName: "creditcard",
            backgroundColor: nil, // Uses design token default
            textColor: .primary,
            borderColor: Color.gray.opacity(0.3),
            isEnabled: isEnabled,
            accessibilityLabel: "Pay with credit or debit card"
        )
    }
}
