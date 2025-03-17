//
//  PaymentFlowScope.swift
//
//
//  Created by Boris on 6.2.25..
//

import SwiftUI

/// Scope interface for customizing the Primer checkout experience.
///
/// This interface provides access to payment method data and selection functionality when implementing a custom checkout
/// experience through `PrimerCheckout`'s `content` parameter closure.
@MainActor
protocol PrimerCheckoutScope {
    /// An AsyncStream containing the list of available payment methods based on prior merchant configuration.
    ///
    /// Each PaymentMethod in this stream contains data to allow for payment method identification along with UI
    /// components for displaying the default experience or a fully custom one.
    func paymentMethods() -> AsyncStream<[any PaymentMethodProtocol]>

    /// An AsyncStream representing the currently selected payment method.
    /// Emits `nil` if no payment method is selected.
    func selectedPaymentMethod() -> AsyncStream<(any PaymentMethodProtocol)?>

    /// Updates the selected payment method for the active checkout flow.
    ///
    /// Use this function to set the payment method before initiating the checkout process.
    ///
    /// - Parameter method: The payment method to select, or `nil` to clear the current selection
    func selectPaymentMethod(_ method: (any PaymentMethodProtocol)?) async
}
