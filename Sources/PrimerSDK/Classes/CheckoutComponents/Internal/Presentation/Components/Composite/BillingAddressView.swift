//
//  BillingAddressView.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Configuration for which billing address fields to show
@available(iOS 15.0, *)
internal struct BillingAddressConfiguration {
    let showFirstName: Bool
    let showLastName: Bool
    let showEmail: Bool
    let showPhoneNumber: Bool
    let showAddressLine1: Bool
    let showAddressLine2: Bool
    let showCity: Bool
    let showState: Bool
    let showPostalCode: Bool
    let showCountry: Bool

    static let full = BillingAddressConfiguration(
        showFirstName: true,
        showLastName: true,
        showEmail: true,
        showPhoneNumber: true,
        showAddressLine1: true,
        showAddressLine2: true,
        showCity: true,
        showState: true,
        showPostalCode: true,
        showCountry: true
    )

    static let minimal = BillingAddressConfiguration(
        showFirstName: false,
        showLastName: false,
        showEmail: false,
        showPhoneNumber: false,
        showAddressLine1: false,
        showAddressLine2: false,
        showCity: false,
        showState: false,
        showPostalCode: true,
        showCountry: true
    )

    static let none = BillingAddressConfiguration(
        showFirstName: false,
        showLastName: false,
        showEmail: false,
        showPhoneNumber: false,
        showAddressLine1: false,
        showAddressLine2: false,
        showCity: false,
        showState: false,
        showPostalCode: false,
        showCountry: false
    )
}

/// A composite SwiftUI view containing billing address fields with dynamic layout
@available(iOS 15.0, *)
internal struct BillingAddressView: View, LogReporter {
    // MARK: - Properties

    /// The card form scope for handling updates
    let cardFormScope: any PrimerCardFormScope

    /// Configuration for which fields to show
    let configuration: BillingAddressConfiguration

    /// Optional styling configuration for customizing field appearance
    let styling: PrimerFieldStyling?

    /// Currently selected country (atomic state for bug-free updates)
    @State private var selectedCountry: CountryCode.PhoneNumberCountryCode?

    /// Show country selector
    @State private var showCountrySelector = false

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    /// Creates a new BillingAddressView with comprehensive customization support
    internal init(
        cardFormScope: any PrimerCardFormScope,
        configuration: BillingAddressConfiguration,
        styling: PrimerFieldStyling? = nil
    ) {
        self.cardFormScope = cardFormScope
        self.configuration = configuration
        self.styling = styling
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Name fields (horizontal layout) - Using ViewBuilder field functions
            if configuration.showFirstName || configuration.showLastName {
                HStack(spacing: 16) {
                    if configuration.showFirstName {
                        AnyView(cardFormScope.PrimerFirstNameField(label: CheckoutComponentsStrings.firstNameLabel, styling: styling))
                    }

                    if configuration.showLastName {
                        AnyView(cardFormScope.PrimerLastNameField(label: CheckoutComponentsStrings.lastNameLabel, styling: styling))
                    }
                }
            }

            // Country - Show first to match Drop-in layout
            if configuration.showCountry {
                AnyView(cardFormScope.PrimerCountryField(label: CheckoutComponentsStrings.countryLabel, styling: styling))
            }

            // Address Line 1 - Using ViewBuilder field functions
            if configuration.showAddressLine1 {
                AnyView(cardFormScope.PrimerAddressLine1Field(label: CheckoutComponentsStrings.addressLine1Label, styling: styling))
            }

            // Postal Code - Show before state to match Drop-in layout
            if configuration.showPostalCode {
                AnyView(cardFormScope.PrimerPostalCodeField(label: CheckoutComponentsStrings.postalCodeLabel, styling: styling))
            }

            // State/Region - Show after postal code to match Drop-in layout
            if configuration.showState {
                AnyView(cardFormScope.PrimerStateField(label: CheckoutComponentsStrings.stateLabel, styling: styling))
            }

            // Address Line 2 - Using ViewBuilder field functions (Optional)
            if configuration.showAddressLine2 {
                AnyView(cardFormScope.PrimerAddressLine2Field(label: CheckoutComponentsStrings.addressLine2Label, styling: styling))
            }

            // City - After address fields
            if configuration.showCity {
                AnyView(cardFormScope.PrimerCityField(label: CheckoutComponentsStrings.cityLabel, styling: styling))
            }

            // Email - Near the end
            if configuration.showEmail {
                AnyView(cardFormScope.PrimerEmailField(label: CheckoutComponentsStrings.emailLabel, styling: styling))
            }

            // Phone Number - Last field
            if configuration.showPhoneNumber {
                AnyView(cardFormScope.PrimerPhoneNumberField(label: CheckoutComponentsStrings.phoneNumberLabel, styling: styling))
            }
        }
        .sheet(isPresented: $showCountrySelector) {
            if let defaultCardFormScope = cardFormScope as? DefaultCardFormScope {
                // Create a custom country scope that updates both code and name
                let countryScope = BillingAddressCountryScope(
                    cardFormScope: defaultCardFormScope,
                    onCountrySelected: { code, name in
                        // Update country state atomically to fix one-step delay bug
                        // Find the dial code from the available countries
                        let dialCode = CountryCode.phoneNumberCountryCodes
                            .first { $0.code == code }?.dialCode ?? ""

                        let newCountry = CountryCode.PhoneNumberCountryCode(
                            name: name,
                            dialCode: dialCode,
                            code: code
                        )
                        selectedCountry = newCountry
                        cardFormScope.updateCountryCode(code)
                        showCountrySelector = false
                    }
                )

                SelectCountryScreen(
                    scope: countryScope,
                    onDismiss: {
                        showCountrySelector = false
                    }
                )
                // .primerModifier() removed - use standard SwiftUI modifiers
            } else {
                // Fallback if scopes aren't available
                Text(CheckoutComponentsStrings.countrySelectorPlaceholder)
                    .padding()
            }
        }
    }

}

// MARK: - Custom Country Scope for Billing Address

/// Custom country scope that handles country selection for billing address
@available(iOS 15.0, *)
@MainActor
internal final class BillingAddressCountryScope: PrimerSelectCountryScope, LogReporter {

    private let cardFormScope: DefaultCardFormScope
    private let onCountrySelectedCallback: (String, String) -> Void
    private var defaultScope: DefaultSelectCountryScope

    init(cardFormScope: DefaultCardFormScope, onCountrySelected: @escaping (String, String) -> Void) {
        self.cardFormScope = cardFormScope
        self.onCountrySelectedCallback = onCountrySelected
        self.defaultScope = DefaultSelectCountryScope(cardFormScope: cardFormScope, checkoutScope: nil)
    }

    var state: AsyncStream<PrimerSelectCountryState> {
        defaultScope.state
    }

    var screen: ((_ scope: PrimerSelectCountryScope) -> AnyView)? {
        get { defaultScope.screen }
        set { defaultScope.screen = newValue }
    }

    var searchBar: ((_ query: String, _ onQueryChange: @escaping (String) -> Void, _ placeholder: String) -> AnyView)? {
        get { defaultScope.searchBar }
        set { defaultScope.searchBar = newValue }
    }

    var countryItem: ((_ country: PrimerCountry, _ onSelect: @escaping () -> Void) -> AnyView)? {
        get { defaultScope.countryItem }
        set { defaultScope.countryItem = newValue }
    }

    func onCountrySelected(countryCode: String, countryName: String) {
        logger.debug(message: "Billing address country selected: \(countryName) (\(countryCode))")
        onCountrySelectedCallback(countryCode, countryName)
    }

    func onCancel() {
        logger.debug(message: "Billing address country selection cancelled")
        // Sheet will be dismissed by onDismiss callback
    }

    func onSearch(query: String) {
        defaultScope.onSearch(query: query)
    }
}
