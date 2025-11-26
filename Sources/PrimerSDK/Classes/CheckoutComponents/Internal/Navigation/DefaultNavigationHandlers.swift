//
//  DefaultNavigationHandlers.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Provides default navigation action factories for checkout flow.
/// These are used as fallbacks when merchants don't provide custom navigation callbacks.
@available(iOS 15.0, *)
@MainActor
struct DefaultNavigationHandlers {

    // MARK: - Checkout Navigation Defaults

    /// Creates default success navigation action
    /// - Parameter navigator: The checkout navigator
    /// - Returns: Action closure that navigates to success screen
    static func defaultSuccess(navigator: CheckoutNavigator) -> () -> Void {
        { [weak navigator] in
            // Success is typically handled by the SDK internally
            // and triggers dismissal via CheckoutComponentsPrimer
        }
    }

    /// Creates default error navigation action
    /// - Parameter navigator: The checkout navigator
    /// - Returns: Action closure that navigates to error screen
    static func defaultError(navigator: CheckoutNavigator) -> (String) -> Void {
        { [weak navigator] message in
            // Error navigation is handled by CheckoutNavigator.navigateToError
            // which delegates to CheckoutComponentsPrimer
        }
    }

    /// Creates default back navigation action
    /// - Parameter navigator: The checkout navigator
    /// - Returns: Action closure that navigates back
    static func defaultBack(navigator: CheckoutNavigator) -> () -> Void {
        { [weak navigator] in
            navigator?.navigateBack()
        }
    }

    /// Creates default cancel navigation action
    /// - Parameter navigator: The checkout navigator
    /// - Returns: Action closure that dismisses checkout
    static func defaultCancel(navigator: CheckoutNavigator) -> () -> Void {
        { [weak navigator] in
            navigator?.dismiss()
        }
    }

    /// Creates default retry navigation action
    /// - Parameter navigator: The checkout navigator
    /// - Returns: Action closure that retries the current operation
    static func defaultRetry(navigator: CheckoutNavigator) -> () -> Void {
        { [weak navigator] in
            navigator?.navigateToPaymentSelection()
        }
    }

    /// Creates default "other payment methods" navigation action
    /// - Parameter navigator: The checkout navigator
    /// - Returns: Action closure that returns to payment method selection
    static func defaultOtherPaymentMethods(navigator: CheckoutNavigator) -> () -> Void {
        { [weak navigator] in
            navigator?.navigateToPaymentSelection()
        }
    }

    // MARK: - Payment Method Selection Defaults

    /// Creates default payment method selected action
    /// - Parameter navigator: The checkout navigator
    /// - Returns: Action closure that navigates to selected payment method
    static func defaultPaymentMethodSelected(navigator: CheckoutNavigator) -> (String) -> Void {
        { [weak navigator] methodId in
            navigator?.navigateToPaymentMethod(methodId)
        }
    }

    // MARK: - Country Selection Defaults

    /// Creates default country selected action
    /// - Returns: Action closure that handles country selection
    static func defaultCountrySelected() -> (String, String) -> Void {
        { _, _ in
            // Country selection is handled by the form's internal state
        }
    }

    /// Creates default show country selection action
    /// - Parameter navigator: The checkout navigator
    /// - Returns: Action closure that shows country picker
    static func defaultShowCountrySelection(navigator: CheckoutNavigator) -> () -> Void {
        { [weak navigator] in
            navigator?.navigateToCountrySelection()
        }
    }
}
