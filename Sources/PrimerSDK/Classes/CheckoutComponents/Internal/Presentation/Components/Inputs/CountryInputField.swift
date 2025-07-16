//
//  CountryInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// A SwiftUI component for country selection with validation
@available(iOS 15.0, *)
internal struct CountryInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String

    /// Placeholder text for the input field
    let placeholder: String

    /// Callback when the country changes
    let onCountryChange: ((String) -> Void)?

    /// Callback when the country code changes
    let onCountryCodeChange: ((String) -> Void)?

    /// Callback when the validation state changes
    let onValidationChange: ((Bool) -> Void)?

    /// Callback to open country selector
    let onOpenCountrySelector: (() -> Void)?

    /// External country for reactive updates (using proper SDK type)
    let selectedCountry: CountryCode.PhoneNumberCountryCode?

    /// PrimerModifier for comprehensive styling customization
    let modifier: PrimerModifier

    // MARK: - Private Properties

    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?

    /// The country name displayed
    @State private var countryName: String = ""

    /// The country code (ISO 2-letter)
    @State private var countryCode: String = ""

    /// The validation state
    @State private var isValid: Bool = false

    /// Error message if validation fails
    @State private var errorMessage: String?

    /// Focus state for input field styling
    @State private var isFocused: Bool = false

    @Environment(\.designTokens) private var tokens

    // MARK: - Computed Properties

    /// Dynamic border color based on field state
    private var borderColor: Color {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            return tokens?.primerColorBorderOutlinedError ?? .red
        } else if isFocused {
            return tokens?.primerColorBorderOutlinedFocus ?? .blue
        } else {
            return tokens?.primerColorBorderOutlinedDefault ?? Color(.systemGray4)
        }
    }

    // MARK: - Initialization

    /// Creates a new CountryInputField with comprehensive customization support
    internal init(
        label: String,
        placeholder: String,
        selectedCountry: CountryCode.PhoneNumberCountryCode? = nil,
        modifier: PrimerModifier = PrimerModifier(),
        onCountryChange: ((String) -> Void)? = nil,
        onCountryCodeChange: ((String) -> Void)? = nil,
        onValidationChange: ((Bool) -> Void)? = nil,
        onOpenCountrySelector: (() -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.selectedCountry = selectedCountry
        self.modifier = modifier
        self.onCountryChange = onCountryChange
        self.onCountryCodeChange = onCountryCodeChange
        self.onValidationChange = onValidationChange
        self.onOpenCountrySelector = onOpenCountrySelector
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: tokens?.primerSpaceSmall ?? 6) {
            // Label
            Text(label)
                .font(tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .system(size: 12, weight: .medium))
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)

            // Country field with selector button using ZStack architecture
            ZStack {
                // Background and border styling
                RoundedRectangle(cornerRadius: tokens?.primerRadiusMedium ?? 8)
                    .fill(tokens?.primerColorBackground ?? Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: tokens?.primerRadiusMedium ?? 8)
                            .stroke(borderColor, lineWidth: 1)
                            .animation(.easeInOut(duration: 0.2), value: borderColor)
                    )
                    .shadow(
                        color: Color.black.opacity(0.04),
                        radius: tokens?.primerSpaceXsmall ?? 2,
                        x: 0,
                        y: 1
                    )

                // Country selector button content
                Button(action: {
                    onOpenCountrySelector?()
                }, label: {
                    HStack {
                        Text(countryName.isEmpty ? placeholder : countryName)
                            .foregroundColor(countryName.isEmpty ?
                                                (tokens?.primerColorTextSecondary ?? .secondary) :
                                                (tokens?.primerColorTextPrimary ?? .primary))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer()
                    }
                    .padding(.leading, tokens?.primerSpaceLarge ?? 16)
                    .padding(.trailing, tokens?.primerSizeXxlarge ?? 60)
                    .padding(.vertical, tokens?.primerSpaceMedium ?? 12)
                })
                .buttonStyle(PlainButtonStyle())

                // Right side overlay (error icon or chevron)
                HStack {
                    Spacer()

                    if let errorMessage = errorMessage, !errorMessage.isEmpty {
                        // Error icon when validation fails
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: tokens?.primerSizeMedium ?? 20, height: tokens?.primerSizeMedium ?? 20)
                            .foregroundColor(tokens?.primerColorIconNegative ?? Color(red: 1.0, green: 0.45, blue: 0.47))
                            .padding(.trailing, tokens?.primerSpaceMedium ?? 12)
                    } else {
                        // Chevron down icon when no error
                        Image(systemName: "chevron.down")
                            .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                            .padding(.trailing, tokens?.primerSpaceMedium ?? 12)
                    }
                }
            }
            .frame(height: tokens?.primerSizeXxxlarge ?? 48)

            // Error message (always reserve space to prevent height changes)
            Text(errorMessage ?? " ")
                .font(tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .system(size: 11, weight: .regular))
                .foregroundColor(tokens?.primerColorTextNegative ?? .red)
                .padding(.top, tokens?.primerSpaceXsmall ?? 4)
                .opacity(errorMessage != nil ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: errorMessage != nil)
        }
        .primerModifier(modifier)
        .onAppear {
            setupValidationService()
            updateFromExternalState()
        }
        .onChange(of: selectedCountry) { newCountry in
            logger.debug(message: "CountryInputField onChange triggered with: \(newCountry?.name ?? "nil") (\(newCountry?.code ?? "nil"))")
            updateFromExternalState(with: newCountry)
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

    /// Updates the field from external state changes using the property
    private func updateFromExternalState() {
        updateFromExternalState(with: selectedCountry)
    }

    /// Updates the field from external state changes using the provided country
    private func updateFromExternalState(with country: CountryCode.PhoneNumberCountryCode?) {
        // Debug: Show what we received
        logger.debug(message: "CountryInputField updateFromExternalState called with country: \(country?.name ?? "nil") (\(country?.code ?? "nil"))")

        // Update directly from the atomic CountryCode.PhoneNumberCountryCode object
        if let country = country, !country.name.isEmpty, !country.code.isEmpty {
            logger.debug(message: "CountryInputField updating from external state: \(country.name) (\(country.code))")
            // Always update to ensure we have the latest state, even if it seems the same
            countryName = country.name
            countryCode = country.code
            validateCountry()
        } else {
            logger.debug(message: "CountryInputField skipping update - country is nil or empty")
        }
    }

    /// Updates the selected country
    func updateCountry(name: String, code: String) {
        countryName = name
        countryCode = code
        onCountryChange?(name)
        onCountryCodeChange?(code)
        validateCountry()
    }

    private func validateCountry() {
        guard let validationService = validationService else { return }

        let result = validationService.validate(
            input: countryCode,
            with: CountryCodeRule()
        )

        isValid = result.isValid
        errorMessage = result.errorMessage
        onValidationChange?(result.isValid)
    }
}
