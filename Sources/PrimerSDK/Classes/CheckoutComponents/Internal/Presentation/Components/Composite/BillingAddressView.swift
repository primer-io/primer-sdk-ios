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

    @Environment(\.designTokens) private var tokens

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Name fields (horizontal layout)
            if configuration.showFirstName || configuration.showLastName {
                HStack(spacing: 16) {
                    if configuration.showFirstName {
                        NameInputField(
                            label: CheckoutComponentsStrings.firstNameLabel,
                            placeholder: CheckoutComponentsStrings.firstNamePlaceholder,
                            inputType: .firstName,
                            onNameChange: { name in
                                cardFormScope.updateFirstName(name)
                            },
                            onValidationChange: { isValid in
                                fieldValidationStates[.firstName] = isValid
                            }
                        )
                    }

                    if configuration.showLastName {
                        NameInputField(
                            label: CheckoutComponentsStrings.lastNameLabel,
                            placeholder: CheckoutComponentsStrings.lastNamePlaceholder,
                            inputType: .lastName,
                            onNameChange: { name in
                                cardFormScope.updateLastName(name)
                            },
                            onValidationChange: { isValid in
                                fieldValidationStates[.lastName] = isValid
                            }
                        )
                    }
                }
            }

            // Email
            if configuration.showEmail {
                EmailInputField(
                    label: CheckoutComponentsStrings.emailLabel,
                    placeholder: CheckoutComponentsStrings.emailPlaceholder,
                    onEmailChange: { email in
                        cardFormScope.updateEmail(email)
                    },
                    onValidationChange: { isValid in
                        fieldValidationStates[.email] = isValid
                    }
                )
            }

            // Phone Number
            if configuration.showPhoneNumber {
                PhoneNumberInputField(
                    label: CheckoutComponentsStrings.phoneNumberLabel,
                    placeholder: CheckoutComponentsStrings.phoneNumberPlaceholder,
                    onPhoneNumberChange: { phone in
                        cardFormScope.updatePhoneNumber(phone)
                    },
                    onValidationChange: { isValid in
                        fieldValidationStates[.phoneNumber] = isValid
                    }
                )
            }

            // Address Line 1
            if configuration.showAddressLine1 {
                AddressLineInputField(
                    label: CheckoutComponentsStrings.addressLine1Label,
                    placeholder: CheckoutComponentsStrings.addressLine1Placeholder,
                    isRequired: true,
                    inputType: .addressLine1,
                    onAddressChange: { address in
                        cardFormScope.updateAddressLine1(address)
                    },
                    onValidationChange: { isValid in
                        fieldValidationStates[.addressLine1] = isValid
                    }
                )
            }

            // Address Line 2
            if configuration.showAddressLine2 {
                AddressLineInputField(
                    label: CheckoutComponentsStrings.addressLine2Label,
                    placeholder: CheckoutComponentsStrings.addressLine2Placeholder,
                    isRequired: false,
                    inputType: .addressLine2,
                    onAddressChange: { address in
                        cardFormScope.updateAddressLine2(address)
                    },
                    onValidationChange: { isValid in
                        fieldValidationStates[.addressLine2] = isValid
                    }
                )
            }

            // City and State (horizontal layout)
            if configuration.showCity || configuration.showState {
                HStack(spacing: 16) {
                    if configuration.showCity {
                        CityInputField(
                            label: CheckoutComponentsStrings.cityLabel,
                            placeholder: CheckoutComponentsStrings.cityPlaceholder,
                            onCityChange: { city in
                                cardFormScope.updateCity(city)
                            },
                            onValidationChange: { isValid in
                                fieldValidationStates[.city] = isValid
                            }
                        )
                    }

                    if configuration.showState {
                        StateInputField(
                            label: CheckoutComponentsStrings.stateLabel,
                            placeholder: CheckoutComponentsStrings.statePlaceholder,
                            onStateChange: { state in
                                cardFormScope.updateState(state)
                            },
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
                        PostalCodeInputField(
                            label: CheckoutComponentsStrings.postalCodeLabel,
                            placeholder: postalCodePlaceholder,
                            countryCode: selectedCountryCode,
                            onPostalCodeChange: { postalCode in
                                cardFormScope.updatePostalCode(postalCode)
                            },
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

/// Phone number input field component
@available(iOS 15.0, *)
private struct PhoneNumberInputField: View {
    let label: String
    let placeholder: String
    let onPhoneNumberChange: ((String) -> Void)?
    let onValidationChange: ((Bool) -> Void)?

    @State private var phoneNumber = ""
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?
    @State private var errorMessage: String?
    @Environment(\.designTokens) private var tokens

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)

            TextField(placeholder, text: $phoneNumber)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.phonePad)
                .padding()
                .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                .cornerRadius(8)
                .onChange(of: phoneNumber) { newValue in
                    onPhoneNumberChange?(newValue)
                    validatePhoneNumber()
                }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 2)
            }
        }
        .onAppear {
            setupValidationService()
        }
    }

    private func setupValidationService() {
        guard let container = container else { return }
        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            // Handle error
        }
    }

    private func validatePhoneNumber() {
        guard let validationService = validationService else { return }
        let result = validationService.validate(input: phoneNumber, with: PhoneNumberRule())
        errorMessage = result.errorMessage
        onValidationChange?(result.isValid)
    }
}
