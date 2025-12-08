//
//  PrimerEnvironment.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Scope Environment Keys

@available(iOS 15.0, *)
private struct PrimerCheckoutScopeKey: EnvironmentKey {
    static let defaultValue: PrimerCheckoutScope? = nil
}

@available(iOS 15.0, *)
private struct PrimerCardFormScopeKey: EnvironmentKey {
    static let defaultValue: PrimerCardFormScope? = nil
}

@available(iOS 15.0, *)
private struct PrimerPaymentMethodSelectionScopeKey: EnvironmentKey {
    static let defaultValue: PrimerPaymentMethodSelectionScope? = nil
}

@available(iOS 15.0, *)
private struct PrimerSelectCountryScopeKey: EnvironmentKey {
    static let defaultValue: PrimerSelectCountryScope? = nil
}

// MARK: - EnvironmentValues Extension

@available(iOS 15.0, *)
public extension EnvironmentValues {
    /// The checkout scope for accessing checkout state and actions
    ///
    /// Access from any custom view embedded in the checkout hierarchy:
    /// ```swift
    /// struct CustomPaymentView: View {
    ///     @Environment(\.primerCheckoutScope) private var checkoutScope
    ///
    ///     var body: some View {
    ///         Button("Cancel") {
    ///             checkoutScope?.onDismiss()
    ///         }
    ///     }
    /// }
    /// ```
    var primerCheckoutScope: PrimerCheckoutScope? {
        get { self[PrimerCheckoutScopeKey.self] }
        set { self[PrimerCheckoutScopeKey.self] = newValue }
    }

    /// The card form scope for accessing card form state and actions
    ///
    /// Access from any custom view embedded in the card form hierarchy:
    /// ```swift
    /// struct CustomCardView: View {
    ///     @Environment(\.primerCardFormScope) private var cardFormScope
    ///
    ///     var body: some View {
    ///         Text("Card: \(cardFormScope?.structuredState.cardNumber.value ?? "")")
    ///     }
    /// }
    /// ```
    var primerCardFormScope: (any PrimerCardFormScope)? {
        get { self[PrimerCardFormScopeKey.self] }
        set { self[PrimerCardFormScopeKey.self] = newValue }
    }

    /// The payment method selection scope for accessing selection state and actions
    ///
    /// Access from any custom view embedded in the payment selection hierarchy:
    /// ```swift
    /// struct CustomSelectionView: View {
    ///     @Environment(\.primerPaymentMethodSelectionScope) private var selectionScope
    ///
    ///     var body: some View {
    ///         // Access available payment methods
    ///     }
    /// }
    /// ```
    var primerPaymentMethodSelectionScope: PrimerPaymentMethodSelectionScope? {
        get { self[PrimerPaymentMethodSelectionScopeKey.self] }
        set { self[PrimerPaymentMethodSelectionScopeKey.self] = newValue }
    }

    /// The select country scope for accessing country selection state and actions
    ///
    /// Access from any custom view embedded in the country selection hierarchy:
    /// ```swift
    /// struct CustomCountryView: View {
    ///     @Environment(\.primerSelectCountryScope) private var countryScope
    ///
    ///     var body: some View {
    ///         // Access available countries
    ///     }
    /// }
    /// ```
    var primerSelectCountryScope: PrimerSelectCountryScope? {
        get { self[PrimerSelectCountryScopeKey.self] }
        set { self[PrimerSelectCountryScopeKey.self] = newValue }
    }
}
