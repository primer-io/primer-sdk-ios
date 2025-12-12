//
//  DefaultNavigationHandlers.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Default navigation action factories. Used as fallbacks when merchants don't provide custom callbacks.
@available(iOS 15.0, *)
@MainActor
struct DefaultNavigationHandlers {

    // MARK: - Checkout Navigation Defaults

    static func defaultSuccess(navigator: CheckoutNavigator) -> () -> Void {
        { [weak navigator] in
        }
    }

    static func defaultError(navigator: CheckoutNavigator) -> (String) -> Void {
        { [weak navigator] _ in
        }
    }

    static func defaultBack(navigator: CheckoutNavigator) -> () -> Void {
        { [weak navigator] in
            navigator?.navigateBack()
        }
    }

    static func defaultCancel(navigator: CheckoutNavigator) -> () -> Void {
        { [weak navigator] in
            navigator?.dismiss()
        }
    }

    static func defaultRetry(navigator: CheckoutNavigator) -> () -> Void {
        { [weak navigator] in
            navigator?.navigateToPaymentSelection()
        }
    }

    static func defaultOtherPaymentMethods(navigator: CheckoutNavigator) -> () -> Void {
        { [weak navigator] in
            navigator?.navigateToPaymentSelection()
        }
    }

    // MARK: - Payment Method Selection Defaults

    static func defaultPaymentMethodSelected(navigator: CheckoutNavigator) -> (String) -> Void {
        { [weak navigator] methodId in
            navigator?.navigateToPaymentMethod(methodId)
        }
    }

    // MARK: - Country Selection Defaults

    static func defaultCountrySelected() -> (String, String) -> Void {
        { _, _ in
            // Handled by form's internal state
        }
    }

    static func defaultShowCountrySelection(navigator: CheckoutNavigator) -> () -> Void {
        { [weak navigator] in
            navigator?.navigateToCountrySelection()
        }
    }
}
