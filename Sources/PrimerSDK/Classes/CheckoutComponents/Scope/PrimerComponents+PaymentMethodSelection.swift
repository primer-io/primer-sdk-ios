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

        public let title: String?
        public let screen: Component?
        public let paymentMethodItem: PaymentMethodItemComponent?
        public let navigation: Navigation

        /// Creates a payment method selection configuration.
        /// - Parameters:
        ///   - title: Custom title. Default: nil (uses SDK default)
        ///   - screen: Full screen override. Default: nil (uses SDK default)
        ///   - paymentMethodItem: Custom item renderer. Default: nil (uses SDK default)
        ///   - navigation: Navigation callbacks. Default: Navigation()
        public init(
            title: String? = nil,
            screen: Component? = nil,
            paymentMethodItem: PaymentMethodItemComponent? = nil,
            navigation: Navigation = Navigation()
        ) {
            self.title = title
            self.screen = screen
            self.paymentMethodItem = paymentMethodItem
            self.navigation = navigation
        }

        // MARK: - Nested Types

        public struct Navigation {
            /// Called when user selects a payment method with type identifier (e.g., "PAYMENT_CARD", "PAYPAL").
            public let onPaymentMethodSelected: ((_ paymentMethodType: String) -> Void)?

            public init(onPaymentMethodSelected: ((_ paymentMethodType: String) -> Void)? = nil) {
                self.onPaymentMethodSelected = onPaymentMethodSelected
            }
        }
    }
}
