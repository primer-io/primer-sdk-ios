import Foundation
import SwiftUI

@available(iOS 15.0, *)
struct PaymentMethodConverter {

    /// Converts a PaymentMethodProtocol to a PaymentMethodDisplayModel for UI presentation
    /// - Parameter method: The payment method protocol instance to convert
    /// - Returns: A display model suitable for UI rendering, or nil if conversion fails
    static func convertToDisplayModel(_ method: PaymentMethodProtocol) -> PaymentMethodDisplayModel? {
        // Use the payment method type for better matching instead of ID
        switch method.type {
        case .applePay:
            return .applePay()
        case .payPal:
            return .payPal()
        case .paymentCard:
            return .card()
        default:
            // Generic conversion for other payment methods
            let idString = String(describing: method.id)
            return PaymentMethodDisplayModel(
                id: idString,
                name: method.name ?? "Unknown Payment Method",
                iconName: "creditcard", // Default icon
                backgroundColor: nil,
                textColor: .primary,
                borderColor: nil,
                isEnabled: true,
                accessibilityLabel: "Pay with \(method.name ?? "Unknown Payment Method")"
            )
        }
    }

    /// Finds the matching PaymentMethodProtocol for a given PaymentMethodDisplayModel
    /// - Parameters:
    ///   - displayModel: The UI display model to match
    ///   - methods: Array of available payment method protocols
    /// - Returns: The matching payment method protocol, or nil if no match found
    static func findMatchingPaymentMethod(for displayModel: PaymentMethodDisplayModel, in methods: [PaymentMethodProtocol]) -> PaymentMethodProtocol? {
        // Match by known IDs first for better reliability
        switch displayModel.id {
        case "payment_card":
            return methods.first(where: { $0.type == .paymentCard })
        case "apple_pay":
            return methods.first(where: { $0.type == .applePay })
        case "paypal":
            return methods.first(where: { $0.type == .payPal })
        default:
            // Fallback to ID or name matching for other payment methods
            return methods.first(where: {
                String(describing: $0.id) == displayModel.id || $0.name == displayModel.name
            })
        }
    }
}
