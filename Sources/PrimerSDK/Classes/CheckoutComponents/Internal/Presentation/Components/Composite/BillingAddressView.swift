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

    /// Currently selected country name
    @State private var selectedCountryName: String = ""

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

            // Country - Show first to match Drop-in layout
            if configuration.showCountry {
                CountryInputField(
                    label: CheckoutComponentsStrings.countryLabel,
                    placeholder: CheckoutComponentsStrings.selectCountryPlaceholder,
                    onCountryChange: { name in
                        selectedCountryName = name
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
                    },
                    selectedCountryName: selectedCountryName.isEmpty ? nil : selectedCountryName,
                    selectedCountryCode: selectedCountryCode.isEmpty ? nil : selectedCountryCode
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

            // Postal Code - Show before state to match Drop-in layout
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
            }

            // State/Region - Show after postal code to match Drop-in layout
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

            // City - After address fields
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

            // Email - Near the end
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

            // Phone Number - Last field
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
        }
        .sheet(isPresented: $showCountrySelector) {
            if let defaultCardFormScope = cardFormScope as? DefaultCardFormScope {
                // Create a custom country scope that updates both code and name
                let countryScope = BillingAddressCountryScope(
                    cardFormScope: defaultCardFormScope,
                    onCountrySelected: { code, name in
                        selectedCountryCode = code
                        selectedCountryName = name
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
            } else {
                // Fallback if scopes aren't available
                Text(CheckoutComponentsStrings.countrySelectorPlaceholder)
                    .padding()
            }
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
