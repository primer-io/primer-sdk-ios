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
    let cardFormScope: DefaultCardFormScope

    /// Configuration for which fields to show
    let configuration: BillingAddressConfiguration

    /// Optional styling configuration for customizing field appearance
    let styling: PrimerFieldStyling?

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    /// Creates a new BillingAddressView with comprehensive customization support
    init(
        cardFormScope: DefaultCardFormScope,
        configuration: BillingAddressConfiguration,
        styling: PrimerFieldStyling? = nil
    ) {
        self.cardFormScope = cardFormScope
        self.configuration = configuration
        self.styling = styling
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Name fields (horizontal layout) - Using closure properties
            if configuration.showFirstName || configuration.showLastName {
                HStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
                    if configuration.showFirstName {
                        if let customField = cardFormScope.firstNameField {
                            AnyView(customField(CheckoutComponentsStrings.firstNameLabel, styling))
                        } else {
                            defaultFirstNameField()
                        }
                    }

                    if configuration.showLastName {
                        if let customField = cardFormScope.lastNameField {
                            AnyView(customField(CheckoutComponentsStrings.lastNameLabel, styling))
                        } else {
                            defaultLastNameField()
                        }
                    }
                }
            }

            // Country - Show first to match Drop-in layout
            if configuration.showCountry {
                if let customField = cardFormScope.countryField {
                    AnyView(customField(CheckoutComponentsStrings.countryLabel, styling))
                } else {
                    defaultCountryField()
                }
            }

            // Address Line 1
            if configuration.showAddressLine1 {
                if let customField = cardFormScope.addressLine1Field {
                    AnyView(customField(CheckoutComponentsStrings.addressLine1Label, styling))
                } else {
                    defaultAddressLine1Field()
                }
            }

            // Postal Code - Show before state to match Drop-in layout
            if configuration.showPostalCode {
                if let customField = cardFormScope.postalCodeField {
                    AnyView(customField(CheckoutComponentsStrings.postalCodeLabel, styling))
                } else {
                    defaultPostalCodeField()
                }
            }

            // State/Region - Show after postal code to match Drop-in layout
            if configuration.showState {
                if let customField = cardFormScope.stateField {
                    AnyView(customField(CheckoutComponentsStrings.stateLabel, styling))
                } else {
                    defaultStateField()
                }
            }

            // Address Line 2 (Optional)
            if configuration.showAddressLine2 {
                if let customField = cardFormScope.addressLine2Field {
                    AnyView(customField(CheckoutComponentsStrings.addressLine2Label, styling))
                } else {
                    defaultAddressLine2Field()
                }
            }

            // City - After address fields
            if configuration.showCity {
                if let customField = cardFormScope.cityField {
                    AnyView(customField(CheckoutComponentsStrings.cityLabel, styling))
                } else {
                    defaultCityField()
                }
            }

            // Email - Near the end
            if configuration.showEmail {
                if let customField = cardFormScope.emailField {
                    AnyView(customField(CheckoutComponentsStrings.emailLabel, styling))
                } else {
                    defaultEmailField()
                }
            }

            // Phone Number - Last field
            if configuration.showPhoneNumber {
                if let customField = cardFormScope.phoneNumberField {
                    AnyView(customField(CheckoutComponentsStrings.phoneNumberLabel, styling))
                } else {
                    defaultPhoneNumberField()
                }
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
            styling: styling
        )
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
