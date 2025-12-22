//
//  CountryInputField.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

@available(iOS 15.0, *)
struct CountryInputField: View, LogReporter {
    // MARK: - Public Properties

    let label: String?
    let placeholder: String
    let styling: PrimerFieldStyling?

    // MARK: - Private Properties

    @ObservedObject private var scope: DefaultCardFormScope
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?
    @State private var countryName: String = ""
    @State private var countryCode: String = ""
    @State private var countryFlag: String?
    @State private var isValid: Bool = false
    @State private var errorMessage: String?
    @State private var isFocused: Bool = false
    @State private var showCountryPicker: Bool = false
    @Environment(\.designTokens) private var tokens

    // MARK: - Computed Properties

    private var countryTextColor: Color {
        guard !countryName.isEmpty else {
            return styling?.placeholderColor ?? CheckoutColors.textPlaceholder(tokens: tokens)
        }
        return styling?.textColor ?? CheckoutColors.textPrimary(tokens: tokens)
    }

    private var selectedCountryFromScope: PrimerCountry? {
        scope.structuredState.selectedCountry
    }

    private var fieldFont: Font {
        styling?.resolvedFont(tokens: tokens) ?? PrimerFont.bodyLarge(tokens: tokens)
    }

    // MARK: - Initialization

    init(
        label: String?,
        placeholder: String,
        scope: DefaultCardFormScope,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.scope = scope
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
                Button(
                    action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()

                        showCountryPicker = true
                    },
                    label: {
                        HStack(spacing: PrimerSpacing.small(tokens: tokens)) {
                            // Flag emoji
                            if let countryFlag, !countryName.isEmpty {
                                Text(countryFlag)
                                    .font(fieldFont)
                            }

                            // Country name or placeholder
                            Text(countryName.isEmpty ? placeholder : countryName)
                                .font(fieldFont)
                                .foregroundColor(countryTextColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer(minLength: 0)
                        }
                        .frame(height: PrimerSize.xxlarge(tokens: tokens))
                        .contentShape(Rectangle())
                    }
                )
                .buttonStyle(PlainButtonStyle())
            },
            rightComponent: {
                Image(systemName: "chevron.down")
                    .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
            }
        )
        .onAppear {
            setupValidationService()
            updateFromExternalState()
        }
        .onChange(of: selectedCountryFromScope) { newCountry in
            updateFromExternalState(with: newCountry)
        }
        .sheet(isPresented: $showCountryPicker) {
            SelectCountryScreen(
                scope: scope.selectCountry,
                onDismiss: {
                    showCountryPicker = false
                }
            )
        }
    }

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

    @MainActor
    private func updateFromExternalState() {
        updateFromExternalState(with: selectedCountryFromScope)
    }

    @MainActor
    private func updateFromExternalState(with country: PrimerCountry?) {
        // Update directly from the PrimerCountry object from the scope
        if let country = country, !country.name.isEmpty, !country.code.isEmpty {
            countryName = country.name
            countryCode = country.code
            countryFlag = country.flag
            validateCountry()
        }
    }

    @MainActor
    func updateCountry(name: String, code: String) {
        countryName = name
        countryCode = code
        scope.updateCountryCode(code)
        validateCountry()
    }

    @MainActor
    private func clearFieldError() {
        scope.clearFieldError(.countryCode)
    }

    @MainActor
    private func setFieldError(message: String, errorCode: String?) {
        scope.setFieldError(.countryCode, message: message, errorCode: errorCode)
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
            clearFieldError()
            scope.updateCountryCodeValidationState(true)
        } else if let message = result.errorMessage {
            setFieldError(message: message, errorCode: result.errorCode)
            scope.updateCountryCodeValidationState(false)
        }
    }
}

#if DEBUG
// MARK: - Preview
// Note: Previews are disabled for CountryInputField because it requires DefaultCardFormScope
// which has complex initialization dependencies. Use the Debug App to test this component.
#endif
