//
//  CardPaymentMethodScope.swift
//
//
//  Created by Boris on 24.3.25..
//

// swiftlint:disable all

import SwiftUI

/**
 * Scope interface for the card payment method, extending PrimerPaymentMethodScope.
 *
 * This scope provides the necessary functionalities for building a customizable card form:
 *
 * 1. Primer-styled SwiftUI components for each payment form field, allowing merchants to:
 *    - Choose which fields to display in their custom form
 *    - Control the order of fields
 *    - Customize labels and other properties for each field
 *
 * 2. Form submission and cancellation behavior:
 *    - submit method to process the card payment form
 *    - cancel method to abort the checkout process
 *
 * 3. Access to state which provides:
 *    - Validation state for controlling custom pay button enablement
 *    - Loading state
 */
@MainActor
protocol CardPaymentMethodScope: PrimerPaymentMethodScope where T == CardPaymentUiState {
    // MARK: - Card field update methods

    /// Updates the card number in the payment method state
    /// - Parameter value: The new card number value
    func updateCardNumber(_ value: String)

    /// Updates the cardholder name in the payment method state
    /// - Parameter value: The new cardholder name value
    func updateCardholderName(_ value: String)

    /// Updates the CVV in the payment method state
    /// - Parameter value: The new CVV value
    func updateCvv(_ value: String)

    /// Updates the expiry month in the payment method state
    /// - Parameter value: The new expiry month value
    func updateExpiryMonth(_ value: String)

    /// Updates the expiry year in the payment method state
    /// - Parameter value: The new expiry year value
    func updateExpiryYear(_ value: String)

    /// Updates the card network in the payment method state
    /// - Parameter network: The detected or selected card network
    func updateCardNetwork(_ network: CardNetwork)

    // MARK: - Card field components

    /// Use this function to display a cardholder name input field in your custom card form implementation.
    /// - Parameters:
    ///   - modifier: The SwiftUI modifier to be applied to the component
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    @ViewBuilder func PrimerCardholderNameField(
        modifier: Any,
        label: String?
    ) -> any View

    /// Use this function to display a card number input field in your custom card form implementation.
    /// - Parameters:
    ///   - modifier: The SwiftUI modifier to be applied to the component
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    @ViewBuilder func PrimerCardNumberField(
        modifier: Any,
        label: String?
    ) -> any View

    /// Use this function to display a CVV input field in your custom card form implementation.
    /// - Parameters:
    ///   - modifier: The SwiftUI modifier to be applied to the component
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    @ViewBuilder func PrimerCvvField(
        modifier: Any,
        label: String?
    ) -> any View

    /// Use this function to display a card expiration input field in your custom card form implementation.
    /// - Parameters:
    ///   - modifier: The SwiftUI modifier to be applied to the component
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    @ViewBuilder func PrimerCardExpirationField(
        modifier: Any,
        label: String?
    ) -> any View

    // MARK: - Billing address field components

    /// Use this function to display a country picker field in your custom card form implementation.
    /// - Parameters:
    ///   - modifier: The SwiftUI modifier to be applied to the component
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    @ViewBuilder func PrimerCountryField(
        modifier: Any,
        label: String?
    ) -> any View

    /// Use this function to display a first name input field in your custom card form implementation.
    /// - Parameters:
    ///   - modifier: The SwiftUI modifier to be applied to the component
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    @ViewBuilder func PrimerFirstNameField(
        modifier: Any,
        label: String?
    ) -> any View

    /// Use this function to display a last name input field in your custom card form implementation.
    /// - Parameters:
    ///   - modifier: The SwiftUI modifier to be applied to the component
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    @ViewBuilder func PrimerLastNameField(
        modifier: Any,
        label: String?
    ) -> any View

    /// Use this function to display an address line 1 input field in your custom card form implementation.
    /// - Parameters:
    ///   - modifier: The SwiftUI modifier to be applied to the component
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    @ViewBuilder func PrimerAddressLine1Field(
        modifier: Any,
        label: String?
    ) -> any View

    /// Use this function to display an address line 2 input field in your custom card form implementation.
    /// - Parameters:
    ///   - modifier: The SwiftUI modifier to be applied to the component
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    @ViewBuilder func PrimerAddressLine2Field(
        modifier: Any,
        label: String?
    ) -> any View

    /// Use this function to display a postal code input field in your custom card form implementation.
    /// - Parameters:
    ///   - modifier: The SwiftUI modifier to be applied to the component
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    @ViewBuilder func PrimerPostalCodeField(
        modifier: Any,
        label: String?
    ) -> any View

    /// Use this function to display a city input field in your custom card form implementation.
    /// - Parameters:
    ///   - modifier: The SwiftUI modifier to be applied to the component
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    @ViewBuilder func PrimerCityField(
        modifier: Any,
        label: String?
    ) -> any View

    /// Use this function to display a state input field in your custom card form implementation.
    /// - Parameters:
    ///   - modifier: The SwiftUI modifier to be applied to the component
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    @ViewBuilder func PrimerStateField(
        modifier: Any,
        label: String?
    ) -> any View

    /// Use this function to display a pay button in your custom card form implementation.
    /// - Parameters:
    ///   - enabled: Whether the button should be enabled or not
    ///   - modifier: The SwiftUI modifier to be applied to the component
    ///   - text: Optional text for the button. If not specified, a default text will be used.
    @ViewBuilder func PrimerPayButton(
        enabled: Bool,
        modifier: Any,
        text: String?
    ) -> any View
}
// swiftlint:enable all
