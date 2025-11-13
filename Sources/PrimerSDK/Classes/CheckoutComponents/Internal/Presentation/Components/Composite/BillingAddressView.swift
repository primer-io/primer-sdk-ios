//
//  BillingAddressView.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Configuration for which billing address fields to show
@available(iOS 15.0, *)
struct BillingAddressConfiguration {
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
}

/// A composite SwiftUI view containing billing address fields with dynamic layout
@available(iOS 15.0, *)
struct BillingAddressView: View, LogReporter {
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
    init(
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
        VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
            // Name fields (horizontal layout) - Using closure properties
            if configuration.showFirstName || configuration.showLastName {
                HStack(spacing: PrimerSpacing.large(tokens: tokens)) {
                    if configuration.showFirstName {
                        if let customField = (cardFormScope as? DefaultCardFormScope)?.firstNameField {
                            AnyView(customField(CheckoutComponentsStrings.firstNameLabel, styling))
                        } else {
                            defaultFirstNameField()
                        }
                    }

                    if configuration.showLastName {
                        if let customField = (cardFormScope as? DefaultCardFormScope)?.lastNameField {
                            AnyView(customField(CheckoutComponentsStrings.lastNameLabel, styling))
                        } else {
                            defaultLastNameField()
                        }
                    }
                }
            }

            // Country - Show first to match Drop-in layout
            if configuration.showCountry {
                if let customField = (cardFormScope as? DefaultCardFormScope)?.countryField {
                    AnyView(customField(CheckoutComponentsStrings.countryLabel, styling))
                } else {
                    defaultCountryField()
                }
            }

            // Address Line 1
            if configuration.showAddressLine1 {
                if let customField = (cardFormScope as? DefaultCardFormScope)?.addressLine1Field {
                    AnyView(customField(CheckoutComponentsStrings.addressLine1Label, styling))
                } else {
                    defaultAddressLine1Field()
                }
            }

            // Postal Code - Show before state to match Drop-in layout
            if configuration.showPostalCode {
                if let customField = (cardFormScope as? DefaultCardFormScope)?.postalCodeField {
                    AnyView(customField(CheckoutComponentsStrings.postalCodeLabel, styling))
                } else {
                    defaultPostalCodeField()
                }
            }

            // State/Region - Show after postal code to match Drop-in layout
            if configuration.showState {
                if let customField = (cardFormScope as? DefaultCardFormScope)?.stateField {
                    AnyView(customField(CheckoutComponentsStrings.stateLabel, styling))
                } else {
                    defaultStateField()
                }
            }

            // Address Line 2 (Optional)
            if configuration.showAddressLine2 {
                if let customField = (cardFormScope as? DefaultCardFormScope)?.addressLine2Field {
                    AnyView(customField(CheckoutComponentsStrings.addressLine2Label, styling))
                } else {
                    defaultAddressLine2Field()
                }
            }

            // City - After address fields
            if configuration.showCity {
                if let customField = (cardFormScope as? DefaultCardFormScope)?.cityField {
                    AnyView(customField(CheckoutComponentsStrings.cityLabel, styling))
                } else {
                    defaultCityField()
                }
            }

            // Email - Near the end
            if configuration.showEmail {
                if let customField = (cardFormScope as? DefaultCardFormScope)?.emailField {
                    AnyView(customField(CheckoutComponentsStrings.emailLabel, styling))
                } else {
                    defaultEmailField()
                }
            }

            // Phone Number - Last field
            if configuration.showPhoneNumber {
                if let customField = (cardFormScope as? DefaultCardFormScope)?.phoneNumberField {
                    AnyView(customField(CheckoutComponentsStrings.phoneNumberLabel, styling))
                } else {
                    defaultPhoneNumberField()
                }
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
                    .padding(PrimerSpacing.large(tokens: tokens))
            }
        }
    }

    // MARK: - Default Field Implementations

    @ViewBuilder
    private func defaultFirstNameField() -> some View {
        NameInputField(
            label: CheckoutComponentsStrings.firstNameLabel,
            placeholder: CheckoutComponentsStrings.firstNamePlaceholder,
            inputType: .firstName,
            scope: cardFormScope,
            styling: styling
        )
    }

    @ViewBuilder
    private func defaultLastNameField() -> some View {
        NameInputField(
            label: CheckoutComponentsStrings.lastNameLabel,
            placeholder: CheckoutComponentsStrings.lastNamePlaceholder,
            inputType: .lastName,
            scope: cardFormScope,
            styling: styling
        )
    }

    @ViewBuilder
    private func defaultCountryField() -> some View {
        CountryInputField(
            label: CheckoutComponentsStrings.countryLabel,
            placeholder: CheckoutComponentsStrings.countrySelectorPlaceholder,
            scope: cardFormScope,
            selectedCountry: selectedCountry,
            styling: styling
        )
        .onTapGesture {
            showCountrySelector = true
        }
    }

    @ViewBuilder
    private func defaultAddressLine1Field() -> some View {
        AddressLineInputField(
            label: CheckoutComponentsStrings.addressLine1Label,
            placeholder: CheckoutComponentsStrings.addressLine1Placeholder,
            isRequired: true,
            inputType: .addressLine1,
            scope: cardFormScope,
            styling: styling
        )
    }

    @ViewBuilder
    private func defaultAddressLine2Field() -> some View {
        AddressLineInputField(
            label: CheckoutComponentsStrings.addressLine2Label,
            placeholder: CheckoutComponentsStrings.addressLine2Placeholder,
            isRequired: false,
            inputType: .addressLine2,
            scope: cardFormScope,
            styling: styling
        )
    }

    @ViewBuilder
    private func defaultCityField() -> some View {
        CityInputField(
            label: CheckoutComponentsStrings.cityLabel,
            placeholder: CheckoutComponentsStrings.cityPlaceholder,
            scope: cardFormScope,
            styling: styling
        )
    }

    @ViewBuilder
    private func defaultStateField() -> some View {
        StateInputField(
            label: CheckoutComponentsStrings.stateLabel,
            placeholder: CheckoutComponentsStrings.statePlaceholder,
            scope: cardFormScope,
            styling: styling
        )
    }

    @ViewBuilder
    private func defaultPostalCodeField() -> some View {
        PostalCodeInputField(
            label: CheckoutComponentsStrings.postalCodeLabel,
            placeholder: CheckoutComponentsStrings.postalCodePlaceholder,
            scope: cardFormScope,
            styling: styling
        )
    }

    @ViewBuilder
    private func defaultEmailField() -> some View {
        EmailInputField(
            label: CheckoutComponentsStrings.emailLabel,
            placeholder: CheckoutComponentsStrings.emailPlaceholder,
            scope: cardFormScope,
            styling: styling
        )
    }

    @ViewBuilder
    private func defaultPhoneNumberField() -> some View {
        // Using NameInputField with phoneNumber type for phone number input
        NameInputField(
            label: CheckoutComponentsStrings.phoneNumberLabel,
            placeholder: CheckoutComponentsStrings.phoneNumberPlaceholder,
            inputType: .phoneNumber,
            scope: cardFormScope,
            styling: styling
        )
    }

}

// MARK: - Custom Country Scope for Billing Address

/// Custom country scope that handles country selection for billing address
@available(iOS 15.0, *)
@MainActor
final class BillingAddressCountryScope: PrimerSelectCountryScope, LogReporter {

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
