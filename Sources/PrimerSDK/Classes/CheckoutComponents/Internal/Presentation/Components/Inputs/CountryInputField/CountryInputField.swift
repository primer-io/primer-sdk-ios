//
//  CountryInputField.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// A SwiftUI component for country selection with validation
@available(iOS 15.0, *)
struct CountryInputField: View, LogReporter {
    // MARK: - Properties

    let label: String?
    let placeholder: String
    let scope: any PrimerCardFormScope
    let selectedCountry: CountryCode.PhoneNumberCountryCode?
    let styling: PrimerFieldStyling?

    // MARK: - Private Properties

    @State private var validationService: ValidationService?
    @State private var countryName: String = ""
    @State private var countryCode: String = ""
    @State private var isValid: Bool = false
    @State private var errorMessage: String?
    @State private var isFocused: Bool = false
    @State private var isNavigating: Bool = false
    @Environment(\.diContainer) private var container
    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    init(
        label: String?,
        placeholder: String,
        scope: any PrimerCardFormScope,
        selectedCountry: CountryCode.PhoneNumberCountryCode? = nil,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.scope = scope
        self.selectedCountry = selectedCountry
        self.styling = styling
    }

    // MARK: - Body

    var body: some View {
        PrimerInputFieldContainer(
            label: label,
            styling: styling,
            text: $countryName,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            textFieldBuilder: {
                CountrySelectionButton(
                    countryName: countryName,
                    placeholder: placeholder,
                    styling: styling,
                    tokens: tokens,
                    scope: scope,
                    isNavigating: $isNavigating
                )
            },
            rightComponent: {
                Image(systemName: "chevron.down")
                    .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
            }
        )
        .onAppear {
            isNavigating = false
            setupValidationService()
            updateFromExternalState()
        }
        .onChange(of: selectedCountry) { newCountry in
            updateFromExternalState(with: newCountry)
        }
    }

    // MARK: - Private Methods

    private func setupValidationService() {
        guard let container else {
            return logger.error(message: "DIContainer not available for CountryInputField")
        }
        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }

    /// Updates the field from external state changes using the property
    @MainActor
    private func updateFromExternalState() {
        updateFromExternalState(with: selectedCountry)
    }

    /// Updates the field from external state changes using the provided country
    @MainActor
    private func updateFromExternalState(with country: CountryCode.PhoneNumberCountryCode?) {
        if let country, !country.name.isEmpty, !country.code.isEmpty {
            countryName = country.name
            countryCode = country.code
            validateCountry()
        }
    }

    @MainActor
    private func validateCountry() {
        guard let validationService = validationService else { return }
        let result = validationService.validate(
            input: countryCode,
            with: CountryCodeRule()
        )
        isValid = result.isValid
        errorMessage = result.errorMessage
        if result.isValid {
            scope.clearFieldError(.countryCode)
            scope.updateValidationStateIfNeeded(for: .countryCode, isValid: true)
        } else if let message = result.errorMessage {
            scope.setFieldError(.countryCode, message: message, errorCode: result.errorCode)
            scope.updateValidationStateIfNeeded(for: .countryCode, isValid: false)
        }
    }
}

#if DEBUG
@available(iOS 15.0, *)
#Preview("Light Mode") {
    CountryInputField(
        label: "Country",
        placeholder: "Select country",
        scope: MockCardFormScope()
    )
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
}

@available(iOS 15.0, *)
#Preview("Dark Mode") {
    CountryInputField(
        label: "Country",
        placeholder: "Select country",
        scope: MockCardFormScope()
    )
    .padding()
    .background(Color.black)
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
}
#endif
