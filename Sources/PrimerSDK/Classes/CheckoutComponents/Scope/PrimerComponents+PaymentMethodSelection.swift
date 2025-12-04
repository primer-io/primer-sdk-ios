//
//  PrimerComponents+PaymentMethodSelection.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - PrimerComponents.PaymentMethodSelection

@available(iOS 15.0, *)
extension PrimerComponents {

    /// Configuration for payment method selection screen.
    public struct PaymentMethodSelection {

        /// Custom title for the screen
        public let title: String?

        /// Full screen override component.
        /// The closure receives the scope for full access to payment methods and navigation actions.
        public let screen: PaymentMethodSelectionScreenComponent?

        /// Custom payment method item renderer
        public let paymentMethodItem: PaymentMethodItemComponent?

        /// Custom category header renderer for grouping payment methods
        public let categoryHeader: CategoryHeaderComponent?

        /// Custom empty state view when no payment methods are available
        public let emptyStateView: Component?

        /// Navigation callback overrides
        public let navigation: Navigation

        /// Creates a new payment method selection configuration.
        /// - Parameters:
        ///   - title: Custom title. Default: nil (uses SDK default)
        ///   - screen: Full screen override with scope access. Default: nil (uses SDK default)
        ///   - paymentMethodItem: Custom item renderer. Default: nil (uses SDK default)
        ///   - categoryHeader: Custom category header renderer. Default: nil (uses SDK default)
        ///   - emptyStateView: Custom empty state view. Default: nil (uses SDK default)
        ///   - navigation: Navigation callbacks. Default: Navigation()
        public init(
            title: String? = nil,
            screen: PaymentMethodSelectionScreenComponent? = nil,
            paymentMethodItem: PaymentMethodItemComponent? = nil,
            categoryHeader: CategoryHeaderComponent? = nil,
            emptyStateView: Component? = nil,
            navigation: Navigation = Navigation()
        ) {
            self.title = title
            self.screen = screen
            self.paymentMethodItem = paymentMethodItem
            self.categoryHeader = categoryHeader
            self.emptyStateView = emptyStateView
            self.navigation = navigation
        }

        // MARK: - Nested Types

        /// Navigation callback overrides for payment method selection
        public struct Navigation {
            /// Called when user selects a payment method
            /// - Parameter paymentMethodType: The payment method type identifier (e.g., "PAYMENT_CARD", "PAYPAL")
            public let onPaymentMethodSelected: ((_ paymentMethodType: String) -> Void)?

            /// Creates a new navigation configuration.
            /// - Parameters:
            ///   - onPaymentMethodSelected: Selection callback. Default: nil (uses SDK default)
            public init(onPaymentMethodSelected: ((_ paymentMethodType: String) -> Void)? = nil) {
                self.onPaymentMethodSelected = onPaymentMethodSelected
            }
        }
    }
}
