//
//  PaymentMethodConverter.swift
//  PrimerSDK - CheckoutComponents
//
//  Converter for payment method types in CheckoutComponents navigation
//  Adapted from ComposableCheckout for CheckoutComponents architecture
//

import Foundation
import SwiftUI

@available(iOS 15.0, *)
internal struct PaymentMethodConverter {

    /// Converts a payment method type string to a CheckoutRoute
    /// - Parameter methodType: The payment method type string
    /// - Returns: The appropriate checkout route for the payment method
    static func convertToRoute(_ methodType: String) -> CheckoutRoute {
        switch methodType.lowercased() {
        case "payment_card", "card":
            return .cardForm
        case "apple_pay":
            return .paymentMethod("APPLE_PAY")
        case "paypal":
            return .paymentMethod("PAYPAL")
        case "klarna":
            return .paymentMethod("KLARNA")
        case "ideal":
            return .paymentMethod("IDEAL")
        default:
            return .paymentMethod(methodType)
        }
    }

    /// Converts a CheckoutRoute back to a payment method type string
    /// - Parameter route: The checkout route
    /// - Returns: The payment method type string, or nil if not a payment method route
    static func convertFromRoute(_ route: CheckoutRoute) -> String? {
        switch route {
        case .cardForm:
            return "PAYMENT_CARD"
        case .paymentMethod(let type):
            return type
        default:
            return nil
        }
    }

    /// Determines if a route represents a payment method
    /// - Parameter route: The checkout route to check
    /// - Returns: True if the route represents a payment method
    static func isPaymentMethodRoute(_ route: CheckoutRoute) -> Bool {
        switch route {
        case .cardForm, .paymentMethod:
            return true
        default:
            return false
        }
    }

    /// Gets the display name for a payment method type
    /// - Parameter methodType: The payment method type string
    /// - Returns: A user-friendly display name
    static func displayName(for methodType: String) -> String {
        switch methodType.uppercased() {
        case "PAYMENT_CARD":
            return "Credit or Debit Card"
        case "APPLE_PAY":
            return "Apple Pay"
        case "PAYPAL":
            return "PayPal"
        case "KLARNA":
            return "Klarna"
        case "IDEAL":
            return "iDEAL"
        case "GOOGLE_PAY":
            return "Google Pay"
        case "SOFORT":
            return "Sofort"
        case "BANCONTACT":
            return "Bancontact"
        case "GIROPAY":
            return "Giropay"
        case "EPS":
            return "EPS"
        case "PRZELEWY24":
            return "Przelewy24"
        case "MULTIBANCO":
            return "Multibanco"
        case "MYBANK":
            return "MyBank"
        case "BLIK":
            return "BLIK"
        case "TRUSTLY":
            return "Trustly"
        case "ADYEN_ALIPAY":
            return "Alipay"
        case "ADYEN_WECHATPAY":
            return "WeChat Pay"
        default:
            // Convert snake_case or UPPER_CASE to Title Case
            return methodType
                .replacingOccurrences(of: "_", with: " ")
                .lowercased()
                .capitalized
        }
    }

    /// Gets the icon name for a payment method type
    /// - Parameter methodType: The payment method type string
    /// - Returns: The system icon name or custom icon identifier
    static func iconName(for methodType: String) -> String {
        switch methodType.uppercased() {
        case "PAYMENT_CARD":
            return "creditcard"
        case "APPLE_PAY":
            return "applelogo"
        case "PAYPAL":
            return "paypal_logo"
        case "KLARNA":
            return "klarna_logo"
        case "IDEAL":
            return "ideal_logo"
        case "GOOGLE_PAY":
            return "googlepay_logo"
        default:
            return "creditcard" // Default fallback
        }
    }

    /// Determines the navigation behavior for a payment method type
    /// - Parameter methodType: The payment method type string
    /// - Returns: The appropriate navigation behavior
    static func navigationBehavior(for methodType: String) -> NavigationBehavior {
        switch methodType.uppercased() {
        case "PAYMENT_CARD":
            return .push // Card form requires form input
        case "APPLE_PAY", "GOOGLE_PAY":
            return .replace // Native payment sheets replace current screen
        default:
            return .push // Most payment methods require additional steps
        }
    }

    /// Checks if a payment method type requires form input
    /// - Parameter methodType: The payment method type string
    /// - Returns: True if the payment method requires form input
    static func requiresFormInput(_ methodType: String) -> Bool {
        switch methodType.uppercased() {
        case "PAYMENT_CARD":
            return true // Card form requires extensive input
        case "APPLE_PAY", "GOOGLE_PAY":
            return false // Native payment sheets handle input
        case "PAYPAL", "KLARNA":
            return false // Web-based flows handle input
        default:
            return true // Most payment methods require some input
        }
    }

    /// Gets the expected next route after payment method selection
    /// - Parameter methodType: The selected payment method type string
    /// - Returns: The appropriate next route in the flow
    static func nextRoute(after methodType: String) -> CheckoutRoute {
        switch methodType.uppercased() {
        case "PAYMENT_CARD":
            return .cardForm
        case "APPLE_PAY", "GOOGLE_PAY", "PAYPAL", "KLARNA":
            return .loading // These will handle their own flows
        default:
            return .paymentMethod(methodType)
        }
    }
}
