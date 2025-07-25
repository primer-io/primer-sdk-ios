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
            // Name fields (horizontal layout) - Using closure properties
            if configuration.showFirstName || configuration.showLastName {
                HStack(spacing: 16) {
                    if configuration.showFirstName {
                        if let customField = (cardFormScope as? DefaultCardFormScope)?.firstNameField {
                            customField(CheckoutComponentsStrings.firstNameLabel, styling)
                        } else {
                            defaultFirstNameField()
                        }
                    }

                    if configuration.showLastName {
                        if let customField = (cardFormScope as? DefaultCardFormScope)?.lastNameField {
                            customField(CheckoutComponentsStrings.lastNameLabel, styling)
                        } else {
                            defaultLastNameField()
                        }
                    }
                }
            }

            // Country - Show first to match Drop-in layout
            if configuration.showCountry {
                if let customField = (cardFormScope as? DefaultCardFormScope)?.countryField {
                    customField(CheckoutComponentsStrings.countryLabel, styling)
                } else {
                    defaultCountryField()
                }
            }

            // Address Line 1
            if configuration.showAddressLine1 {
                if let customField = (cardFormScope as? DefaultCardFormScope)?.addressLine1Field {
                    customField(CheckoutComponentsStrings.addressLine1Label, styling)
                } else {
                    defaultAddressLine1Field()
                }
            }

            // Postal Code - Show before state to match Drop-in layout
            if configuration.showPostalCode {
                if let customField = (cardFormScope as? DefaultCardFormScope)?.postalCodeField {
                    customField(CheckoutComponentsStrings.postalCodeLabel, styling)
                } else {
                    defaultPostalCodeField()
                }
            }

            // State/Region - Show after postal code to match Drop-in layout
            if configuration.showState {
                if let customField = (cardFormScope as? DefaultCardFormScope)?.stateField {
                    customField(CheckoutComponentsStrings.stateLabel, styling)
                } else {
                    defaultStateField()
                }
            }

            // Address Line 2 (Optional)
            if configuration.showAddressLine2 {
                if let customField = (cardFormScope as? DefaultCardFormScope)?.addressLine2Field {
                    customField(CheckoutComponentsStrings.addressLine2Label, styling)
                } else {
                    defaultAddressLine2Field()
                }
            }

            // City - After address fields
            if configuration.showCity {
                if let customField = (cardFormScope as? DefaultCardFormScope)?.cityField {
                    customField(CheckoutComponentsStrings.cityLabel, styling)
                } else {
                    defaultCityField()
                }
            }

            // Email - Near the end
            if configuration.showEmail {
                if let customField = (cardFormScope as? DefaultCardFormScope)?.emailField {
                    customField(CheckoutComponentsStrings.emailLabel, styling)
                } else {
                    defaultEmailField()
                }
            }

            // Phone Number - Last field
            if configuration.showPhoneNumber {
                if let customField = (cardFormScope as? DefaultCardFormScope)?.phoneNumberField {
                    customField(CheckoutComponentsStrings.phoneNumberLabel, styling)
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
                    .padding()
            }
        }
    }
    
    // MARK: - Default Field Implementations
    
    @ViewBuilder
    private func defaultFirstNameField() -> some View {
        NameInputField(
            label: CheckoutComponentsStrings.firstNameLabel,
            placeholder: "John",
            inputType: .firstName,
            styling: styling,
            onNameChange: { [weak cardFormScope] name in
                cardFormScope?.updateFirstName(name)
            },
            onValidationChange: { _ in
                // Validation is handled internally by the field
            }
        )
    }
    
    @ViewBuilder
    private func defaultLastNameField() -> some View {
        NameInputField(
            label: CheckoutComponentsStrings.lastNameLabel,
            placeholder: "Smith",
            inputType: .lastName,
            styling: styling,
            onNameChange: { [weak cardFormScope] name in
                cardFormScope?.updateLastName(name)
            },
            onValidationChange: { _ in
                // Validation is handled internally by the field
            }
        )
    }

    @ViewBuilder
    private func defaultCountryField() -> some View {
        CountryInputField(
            label: CheckoutComponentsStrings.countryLabel,
            placeholder: CheckoutComponentsStrings.countrySelectorPlaceholder,
            selectedCountry: selectedCountry,
            styling: styling,
            onCountryChange: { [weak cardFormScope] countryCode in
                cardFormScope?.updateCountryCode(countryCode)
            },
            onValidationChange: { _ in
                // Validation is handled internally by the field
            }
        )
        .onTapGesture {
            showCountrySelector = true
        }
    }
    
    @ViewBuilder
    private func defaultAddressLine1Field() -> some View {
        AddressLineInputField(
            label: CheckoutComponentsStrings.addressLine1Label,
            placeholder: "123 Main St",
            isRequired: true,
            inputType: .addressLine1,
            styling: styling,
            onAddressChange: { [weak cardFormScope] address in
                cardFormScope?.updateAddressLine1(address)
            },
            onValidationChange: { _ in
                // Validation is handled internally by the field
            }
        )
    }
    
    @ViewBuilder
    private func defaultAddressLine2Field() -> some View {
        AddressLineInputField(
            label: CheckoutComponentsStrings.addressLine2Label,
            placeholder: "Apt 4B",
            isRequired: false,
            inputType: .addressLine2,
            styling: styling,
            onAddressChange: { [weak cardFormScope] address in
                cardFormScope?.updateAddressLine2(address)
            },
            onValidationChange: { _ in
                // Validation is handled internally by the field
            }
        )
    }
    
    @ViewBuilder
    private func defaultCityField() -> some View {
        CityInputField(
            label: CheckoutComponentsStrings.cityLabel,
            placeholder: "New York",
            styling: styling,
            onCityChange: { [weak cardFormScope] city in
                cardFormScope?.updateCity(city)
            },
            onValidationChange: { _ in
                // Validation is handled internally by the field
            }
        )
    }
    
    @ViewBuilder
    private func defaultStateField() -> some View {
        StateInputField(
            label: CheckoutComponentsStrings.stateLabel,
            placeholder: "NY",
            styling: styling,
            onStateChange: { [weak cardFormScope] state in
                cardFormScope?.updateState(state)
            },
            onValidationChange: { _ in
                // Validation is handled internally by the field
            }
        )
    }
    
    @ViewBuilder
    private func defaultPostalCodeField() -> some View {
        PostalCodeInputField(
            label: CheckoutComponentsStrings.postalCodeLabel,
            placeholder: "10001",
            styling: styling,
            onPostalCodeChange: { [weak cardFormScope] postalCode in
                cardFormScope?.updatePostalCode(postalCode)
            },
            onValidationChange: { _ in
                // Validation is handled internally by the field
            }
        )
    }
    
    @ViewBuilder
    private func defaultEmailField() -> some View {
        EmailInputField(
            label: CheckoutComponentsStrings.emailLabel,
            placeholder: "john.smith@example.com",
            styling: styling,
            onEmailChange: { [weak cardFormScope] email in
                cardFormScope?.updateEmail(email)
            },
            onValidationChange: { _ in
                // Validation is handled internally by the field
            }
        )
    }
    
    @ViewBuilder
    private func defaultPhoneNumberField() -> some View {
        // Using NameInputField with phoneNumber type for phone number input
        NameInputField(
            label: CheckoutComponentsStrings.phoneNumberLabel,
            placeholder: "+1 (555) 123-4567",
            inputType: .phoneNumber,
            styling: styling,
            onNameChange: { [weak cardFormScope] phoneNumber in
                cardFormScope?.updatePhoneNumber(phoneNumber)
            },
            onValidationChange: { _ in
                // Validation is handled internally by the field
            }
        )
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
