//
//  PrimerCheckoutScope.swift
//  PrimerSDK
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// The main scope interface for PrimerCheckout, providing lifecycle control and customizable UI components.
/// This protocol matches the Android Composable API exactly for cross-platform consistency.
@MainActor
public protocol PrimerCheckoutScope: AnyObject {

    /// The current state of the checkout flow as an async stream.
    var state: AsyncStream<State> { get }

    // MARK: - Customizable Screens

    /// Container view that wraps all checkout content.
    /// Default implementation provides standard checkout container.
    var container: (@ViewBuilder (_ content: @escaping () -> any View) -> any View)? { get set }

    /// Splash screen shown during initialization.
    /// Default implementation shows Primer branding.
    var splashScreen: (@ViewBuilder () -> any View)? { get set }

    /// Loading screen shown during async operations.
    /// Default implementation shows activity indicator.
    var loadingScreen: (@ViewBuilder () -> any View)? { get set }

    /// Success screen shown after successful payment.
    /// Default implementation shows checkmark and success message.
    var successScreen: (@ViewBuilder () -> any View)? { get set }

    /// Error screen shown when an error occurs.
    /// Default implementation shows error icon and message.
    var errorScreen: (@ViewBuilder (_ message: String) -> any View)? { get set }

    // MARK: - Nested Scopes

    /// Scope for card form interactions and customization.
    var cardForm: PrimerCardFormScope { get }

    /// Scope for payment method selection screen.
    var paymentMethodSelection: PrimerPaymentMethodSelectionScope { get }

    // MARK: - Future Payment Method Scopes

    // The following payment method scopes are placeholders for future functionality.
    // They are commented out to indicate planned support but are not yet implemented.

    /// Apple Pay scope (Future feature).
    // var applePay: PrimerApplePayScope { get }

    /// PayPal scope (Future feature).
    // var payPal: PrimerPayPalScope { get }

    /// Google Pay scope (Future feature).
    // var googlePay: PrimerGooglePayScope { get }

    /// Bank transfer scope (Future feature).
    // var bankTransfer: PrimerBankTransferScope { get }

    /// Klarna scope (Future feature).
    // var klarna: PrimerKlarnaScope { get }

    // MARK: - Navigation

    /// Dismisses the checkout flow.
    func onDismiss()

    // MARK: - State Definition

    /// Represents the current state of the checkout flow.
    enum State: Equatable {
        /// Initial state while loading configuration and payment methods.
        case initializing

        /// Ready state with payment methods loaded.
        case ready

        /// Checkout has been dismissed by user or merchant.
        case dismissed

        /// An error occurred during checkout.
        case error(PrimerError)

        public static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.initializing, .initializing),
                 (.ready, .ready),
                 (.dismissed, .dismissed):
                return true
            case let (.error(lhsError), .error(rhsError)):
                return lhsError.errorId == rhsError.errorId
            default:
                return false
            }
        }
    }
}

// MARK: - Public Type Aliases

/// Modifier type for customizing component appearance.
/// Maps to Android's Modifier concept.
public struct PrimerModifier {
    public var padding: EdgeInsets?
    public var background: Color?
    public var cornerRadius: CGFloat?
    public var border: (color: Color, width: CGFloat)?

    public init(
        padding: EdgeInsets? = nil,
        background: Color? = nil,
        cornerRadius: CGFloat? = nil,
        border: (color: Color, width: CGFloat)? = nil
    ) {
        self.padding = padding
        self.background = background
        self.cornerRadius = cornerRadius
        self.border = border
    }
}
