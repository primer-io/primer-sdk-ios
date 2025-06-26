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

    /// Validation states using ValidationService
    @State private var firstNameError: ValidationError?
    @State private var lastNameError: ValidationError?
    @State private var emailError: ValidationError?
    @State private var phoneNumberError: ValidationError?
    @State private var addressLine1Error: ValidationError?
    @State private var addressLine2Error: ValidationError?
    @State private var cityError: ValidationError?
    @State private var stateError: ValidationError?
    @State private var postalCodeError: ValidationError?

    @Environment(\.designTokens) private var tokens
    @Environment(\.diContainer) private var diContainer

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
                                validateFirstName(name)
                            },
                            isError: firstNameError != nil,
                            validationError: firstNameError
                        )
                    }

                    if configuration.showLastName {
                        PrimerInputField.lastName(
                            value: lastName,
                            onValueChange: { name in
                                lastName = name
                                cardFormScope.updateLastName(name)
                                validateLastName(name)
                            },
                            isError: lastNameError != nil,
                            validationError: lastNameError
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
                        validateEmail(emailValue)
                    },
                    isError: emailError != nil,
                    validationError: emailError
                )
            }

            // Phone Number - Using PrimerInputField with Android parity
            if configuration.showPhoneNumber {
                PrimerInputField.phoneNumber(
                    value: phoneNumber,
                    onValueChange: { phone in
                        phoneNumber = phone
                        cardFormScope.updatePhoneNumber(phone)
                        validatePhoneNumber(phone)
                    },
                    isError: phoneNumberError != nil,
                    validationError: phoneNumberError
                )
            }

            // Address Line 1 - Using PrimerInputField with Android parity
            if configuration.showAddressLine1 {
                PrimerInputField.addressLine(
                    value: addressLine1,
                    onValueChange: { address in
                        addressLine1 = address
                        cardFormScope.updateAddressLine1(address)
                        validateAddressLine1(address)
                    },
                    labelText: CheckoutComponentsStrings.addressLine1Label,
                    placeholderText: CheckoutComponentsStrings.addressLine1Placeholder,
                    isError: addressLine1Error != nil,
                    validationError: addressLine1Error
                )
            }

            // Address Line 2 - Using PrimerInputField with Android parity (Optional)
            if configuration.showAddressLine2 {
                PrimerInputField.addressLine(
                    value: addressLine2,
                    onValueChange: { address in
                        addressLine2 = address
                        cardFormScope.updateAddressLine2(address)
                        validateAddressLine2(address)
                    },
                    labelText: CheckoutComponentsStrings.addressLine2Label,
                    placeholderText: CheckoutComponentsStrings.addressLine2Placeholder,
                    isError: addressLine2Error != nil,
                    validationError: addressLine2Error
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
                                validateCity(cityValue)
                            },
                            labelText: CheckoutComponentsStrings.cityLabel,
                            placeholderText: CheckoutComponentsStrings.cityPlaceholder,
                            isError: cityError != nil,
                            validationError: cityError
                        )
                    }

                    if configuration.showState {
                        PrimerInputField.addressLine(
                            value: state,
                            onValueChange: { stateValue in
                                state = stateValue
                                cardFormScope.updateState(stateValue)
                                validateState(stateValue)
                            },
                            labelText: CheckoutComponentsStrings.stateLabel,
                            placeholderText: CheckoutComponentsStrings.statePlaceholder,
                            isError: stateError != nil,
                            validationError: stateError
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
                                validatePostalCode(postalCodeValue)
                            },
                            labelText: CheckoutComponentsStrings.postalCodeLabel,
                            placeholderText: postalCodePlaceholder,
                            isError: postalCodeError != nil,
                            validationError: postalCodeError
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
                            onValidationChange: { _ in
                                // Handle country validation state
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

    /// Returns whether all visible fields are valid using ValidationService
    var isValid: Bool {
        // Check all visible required fields have no validation errors
        var hasErrors = false

        if configuration.showFirstName && firstNameError != nil { hasErrors = true }
        if configuration.showLastName && lastNameError != nil { hasErrors = true }
        if configuration.showEmail && emailError != nil { hasErrors = true }
        if configuration.showPhoneNumber && phoneNumberError != nil { hasErrors = true }
        if configuration.showAddressLine1 && addressLine1Error != nil { hasErrors = true }
        // Address line 2 is optional
        if configuration.showCity && cityError != nil { hasErrors = true }
        if configuration.showState && stateError != nil { hasErrors = true }
        if configuration.showPostalCode && postalCodeError != nil { hasErrors = true }

        return !hasErrors
    }

    // MARK: - Validation Helpers

    /// Validates a field using ValidationService from DI container
    private func validateField(type: PrimerInputElementType, value: String) async -> ValidationError? {
        do {
            guard let validationService = try await diContainer?.resolve(ValidationService.self) else {
                // Fallback to basic validation if DI container is not available
                return nil
            }

            let result = validationService.validateField(type: type, value: value.isEmpty ? nil : value)
            if result.isValid {
                return nil
            } else {
                return ValidationError(code: result.errorCode ?? "invalid", message: result.errorMessage ?? "Invalid input")
            }
        } catch {
            // If validation service is not available, don't show errors
            return nil
        }
    }

    /// Validates first name field
    private func validateFirstName(_ value: String) {
        Task {
            firstNameError = await validateField(type: .firstName, value: value)
        }
    }

    /// Validates last name field
    private func validateLastName(_ value: String) {
        Task {
            lastNameError = await validateField(type: .lastName, value: value)
        }
    }

    /// Validates email field
    private func validateEmail(_ value: String) {
        Task {
            emailError = await validateField(type: .email, value: value)
        }
    }

    /// Validates phone number field
    private func validatePhoneNumber(_ value: String) {
        Task {
            phoneNumberError = await validateField(type: .phoneNumber, value: value)
        }
    }

    /// Validates address line 1 field
    private func validateAddressLine1(_ value: String) {
        Task {
            addressLine1Error = await validateField(type: .addressLine1, value: value)
        }
    }

    /// Validates address line 2 field
    private func validateAddressLine2(_ value: String) {
        Task {
            addressLine2Error = await validateField(type: .addressLine2, value: value)
        }
    }

    /// Validates city field
    private func validateCity(_ value: String) {
        Task {
            cityError = await validateField(type: .city, value: value)
        }
    }

    /// Validates state field
    private func validateState(_ value: String) {
        Task {
            stateError = await validateField(type: .state, value: value)
        }
    }

    /// Validates postal code field
    private func validatePostalCode(_ value: String) {
        Task {
            postalCodeError = await validateField(type: .postalCode, value: value)
        }
    }
}
