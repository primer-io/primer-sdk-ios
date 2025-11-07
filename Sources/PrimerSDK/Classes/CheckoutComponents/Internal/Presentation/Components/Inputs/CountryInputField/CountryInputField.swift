//
//  CountryInputField.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// A SwiftUI component for country selection with validation
@available(iOS 15.0, *)
struct CountryInputField: View, LogReporter {
    // MARK: - Public Properties

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

    private var countryTextColor: Color {
        guard !countryName.isEmpty else {
            return styling?.placeholderColor ?? CheckoutColors.textPlaceholder(tokens: tokens)
        }
        return styling?.textColor ?? CheckoutColors.textPrimary(tokens: tokens)
    }

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
                Button(action: {
                    guard !isNavigating else {
                        return
                    }
                    isNavigating = true
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    scope.navigateToCountrySelection()
                    // Reset after shorter timeout - 1 second should be enough
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.isNavigating = false
                    }
                }) {
                    HStack(spacing: 0) {
                        Text(countryName.isEmpty ? placeholder : countryName)
                            .font(styling?.font ?? PrimerFont.bodyLarge(tokens: tokens))
                            .foregroundColor(countryTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer(minLength: 0)
                    }
                    .frame(height: PrimerSize.xxlarge(tokens: tokens))
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isNavigating)
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
        guard let container = container else {
            logger.error(message: "DIContainer not available for CountryInputField")
            return
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
        // Update directly from the atomic CountryCode.PhoneNumberCountryCode object
        if let country, !country.name.isEmpty, !country.code.isEmpty {
            countryName = country.name
            countryCode = country.code
            validateCountry()
        }
    }

    /// Updates the selected country
    @MainActor
    func updateCountry(name: String, code: String) {
        countryName = name
        countryCode = code
        scope.updateCountryCode(code)
        validateCountry()
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
        // Update scope state based on validation
        if result.isValid {
            scope.clearFieldError(.countryCode)
            // Update scope validation state
            if let scope = scope as? DefaultCardFormScope {
                scope.updateCountryCodeValidationState(true)
            }
        } else if let message = result.errorMessage {
            scope.setFieldError(.countryCode, message: message, errorCode: result.errorCode)
            // Update scope validation state
            if let scope = scope as? DefaultCardFormScope {
                scope.updateCountryCodeValidationState(false)
            }
        }
    }
}

#if DEBUG

// MARK: - Preview

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
