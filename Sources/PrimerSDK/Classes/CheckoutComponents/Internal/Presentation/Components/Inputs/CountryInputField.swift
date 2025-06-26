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

    /// External country name for reactive updates
    let selectedCountryName: String?

    /// External country code for reactive updates
    let selectedCountryCode: String?

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

    @Environment(\.designTokens) private var tokens

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)

            // Country field with selector button
            Button(action: {
                onOpenCountrySelector?()
            }) {
                HStack {
                    Text(countryName.isEmpty ? placeholder : countryName)
                        .foregroundColor(countryName.isEmpty ? (tokens?.primerColorTextSecondary ?? .secondary) : (tokens?.primerColorTextPrimary ?? .primary))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.down")
                        .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                }
                .padding()
                .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())

            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 2)
            }
        }
        .onAppear {
            setupValidationService()
            updateFromExternalState()
        }
        .onChange(of: selectedCountryName) { _ in
            updateFromExternalState()
        }
        .onChange(of: selectedCountryCode) { _ in
            updateFromExternalState()
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

    /// Updates the field from external state changes
    private func updateFromExternalState() {
        if let selectedName = selectedCountryName, let selectedCode = selectedCountryCode {
            logger.debug(message: "CountryInputField updating from external state: \(selectedName) (\(selectedCode))")
            countryName = selectedName
            countryCode = selectedCode
            validateCountry()
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
