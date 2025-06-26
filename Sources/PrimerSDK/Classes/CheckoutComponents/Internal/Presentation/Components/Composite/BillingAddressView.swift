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
internal struct BillingAddressView: View {
    // MARK: - Properties

    /// The card form scope for handling updates
    let cardFormScope: PrimerCardFormScope

    /// Configuration for which fields to show
    let configuration: BillingAddressConfiguration

    /// Currently selected country code
    @State private var selectedCountryCode: String = ""

    /// Show country selector
    @State private var showCountrySelector = false

    /// Validation states
    @State private var fieldValidationStates: [PrimerInputElementType: Bool] = [:]

    /// Field values for PrimerInputField integration
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var addressLine1: String = ""
    @State private var addressLine2: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var postalCode: String = ""

    @Environment(\.designTokens) private var tokens

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Name fields (horizontal layout) - Using PrimerInputField with Android parity
            if configuration.showFirstName || configuration.showLastName {
                HStack(spacing: 16) {
                    if configuration.showFirstName {
                        PrimerInputField.firstName(
                            value: firstName,
                            onValueChange: { name in
                                firstName = name
                                cardFormScope.updateFirstName(name)
                            },
                            onValidationChange: { isValid in
                                fieldValidationStates[.firstName] = isValid
                            }
                        )
                    }

                    if configuration.showLastName {
                        PrimerInputField.lastName(
                            value: lastName,
                            onValueChange: { name in
                                lastName = name
                                cardFormScope.updateLastName(name)
                            },
                            onValidationChange: { isValid in
                                fieldValidationStates[.lastName] = isValid
                            }
                        )
                    }
                }
            }

            // Email - Using PrimerInputField with Android parity
            if configuration.showEmail {
                PrimerInputField.email(
                    value: email,
                    onValueChange: { emailValue in
                        email = emailValue
                        cardFormScope.updateEmail(emailValue)
                    },
                    onValidationChange: { isValid in
                        fieldValidationStates[.email] = isValid
                    }
                )
            }

            // Phone Number - Using PrimerInputField with Android parity
            if configuration.showPhoneNumber {
                PrimerInputField.phoneNumber(
                    value: phoneNumber,
                    onValueChange: { phone in
                        phoneNumber = phone
                        cardFormScope.updatePhoneNumber(phone)
                    },
                    onValidationChange: { isValid in
                        fieldValidationStates[.phoneNumber] = isValid
                    }
                )
            }

            // Address Line 1 - Using PrimerInputField with Android parity
            if configuration.showAddressLine1 {
                PrimerInputField.addressLine(
                    value: addressLine1,
                    onValueChange: { address in
                        addressLine1 = address
                        cardFormScope.updateAddressLine1(address)
                    },
                    labelText: CheckoutComponentsStrings.addressLine1Label,
                    placeholderText: CheckoutComponentsStrings.addressLine1Placeholder,
                    inputElementType: .addressLine1,
                    isRequired: true,
                    onValidationChange: { isValid in
                        fieldValidationStates[.addressLine1] = isValid
                    }
                )
            }

            // Address Line 2 - Using PrimerInputField with Android parity (Optional)
            if configuration.showAddressLine2 {
                PrimerInputField.addressLine(
                    value: addressLine2,
                    onValueChange: { address in
                        addressLine2 = address
                        cardFormScope.updateAddressLine2(address)
                    },
                    labelText: CheckoutComponentsStrings.addressLine2Label,
                    placeholderText: CheckoutComponentsStrings.addressLine2Placeholder,
                    inputElementType: .addressLine2,
                    isRequired: false,
                    onValidationChange: { isValid in
                        fieldValidationStates[.addressLine2] = isValid
                    }
                )
            }

            // City and State (horizontal layout) - Using PrimerInputField with Android parity
            if configuration.showCity || configuration.showState {
                HStack(spacing: 16) {
                    if configuration.showCity {
                        PrimerInputField.addressLine(
                            value: city,
                            onValueChange: { cityValue in
                                city = cityValue
                                cardFormScope.updateCity(cityValue)
                            },
                            labelText: CheckoutComponentsStrings.cityLabel,
                            placeholderText: CheckoutComponentsStrings.cityPlaceholder,
                            inputElementType: .city,
                            isRequired: true,
                            onValidationChange: { isValid in
                                fieldValidationStates[.city] = isValid
                            }
                        )
                    }

                    if configuration.showState {
                        PrimerInputField.addressLine(
                            value: state,
                            onValueChange: { stateValue in
                                state = stateValue
                                cardFormScope.updateState(stateValue)
                            },
                            labelText: CheckoutComponentsStrings.stateLabel,
                            placeholderText: CheckoutComponentsStrings.statePlaceholder,
                            inputElementType: .state,
                            isRequired: true,
                            onValidationChange: { isValid in
                                fieldValidationStates[.state] = isValid
                            }
                        )
                        .frame(maxWidth: 100)
                    }
                }
            }

            // Postal Code and Country (horizontal layout)
            if configuration.showPostalCode || configuration.showCountry {
                HStack(spacing: 16) {
                    if configuration.showPostalCode {
                        PrimerInputField.addressLine(
                            value: postalCode,
                            onValueChange: { postalCodeValue in
                                postalCode = postalCodeValue
                                cardFormScope.updatePostalCode(postalCodeValue)
                            },
                            labelText: CheckoutComponentsStrings.postalCodeLabel,
                            placeholderText: postalCodePlaceholder,
                            inputElementType: .postalCode,
                            isRequired: true,
                            onValidationChange: { isValid in
                                fieldValidationStates[.postalCode] = isValid
                            }
                        )
                        .frame(maxWidth: 150)
                    }

                    if configuration.showCountry {
                        CountryInputField(
                            label: CheckoutComponentsStrings.countryLabel,
                            placeholder: CheckoutComponentsStrings.selectCountryPlaceholder,
                            onCountryChange: { _ in
                                // Country name handled by code callback
                            },
                            onCountryCodeChange: { code in
                                selectedCountryCode = code
                                cardFormScope.updateCountryCode(code)
                            },
                            onValidationChange: { isValid in
                                fieldValidationStates[.countryCode] = isValid
                            },
                            onOpenCountrySelector: {
                                showCountrySelector = true
                            }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showCountrySelector) {
            // Country selector would go here
            // For now, just a placeholder
            Text(CheckoutComponentsStrings.countrySelectorPlaceholder)
                .padding()
        }
    }

    private var postalCodePlaceholder: String {
        switch selectedCountryCode {
        case "US":
            return "12345"
        case "GB":
            return "SW1A 1AA"
        case "CA":
            return "K1A 0B1"
        default:
            return "Postal Code"
        }
    }

    /// Returns whether all visible fields are valid
    var isValid: Bool {
        var requiredFields: [PrimerInputElementType] = []

        if configuration.showFirstName { requiredFields.append(.firstName) }
        if configuration.showLastName { requiredFields.append(.lastName) }
        if configuration.showEmail { requiredFields.append(.email) }
        if configuration.showPhoneNumber { requiredFields.append(.phoneNumber) }
        if configuration.showAddressLine1 { requiredFields.append(.addressLine1) }
        // Address line 2 is optional
        if configuration.showCity { requiredFields.append(.city) }
        if configuration.showState { requiredFields.append(.state) }
        if configuration.showPostalCode { requiredFields.append(.postalCode) }
        if configuration.showCountry { requiredFields.append(.countryCode) }

        return requiredFields.allSatisfy { field in
            fieldValidationStates[field] ?? false
        }
    }
}
