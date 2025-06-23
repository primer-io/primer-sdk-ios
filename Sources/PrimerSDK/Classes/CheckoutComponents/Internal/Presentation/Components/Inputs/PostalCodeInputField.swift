//
//  PostalCodeInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// A SwiftUI component for postal code input with validation
@available(iOS 15.0, *)
internal struct PostalCodeInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String

    /// Placeholder text for the input field
    let placeholder: String

    /// Country code for validation (optional)
    let countryCode: String?

    /// Callback when the postal code changes
    let onPostalCodeChange: ((String) -> Void)?

    /// Callback when the validation state changes
    let onValidationChange: ((Bool) -> Void)?

    // MARK: - Private Properties

    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?

    /// The postal code entered by the user
    @State private var postalCode: String = ""

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

            // Postal code input field
            TextField(placeholder, text: $postalCode)
                .textFieldStyle(.roundedBorder)
                .keyboardType(keyboardTypeForCountry)
                .autocapitalization(.allCharacters)
                .padding()
                .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                .cornerRadius(8)
                .onChange(of: postalCode) { newValue in
                    onPostalCodeChange?(newValue)
                    validatePostalCode()
                }

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
        }
    }

    private var keyboardTypeForCountry: UIKeyboardType {
        // US ZIP codes are numeric
        if countryCode == "US" {
            return .numberPad
        }
        // Default to alphanumeric for other countries
        return .default
    }

    private func setupValidationService() {
        guard let container = container else {
            logger.error(message: "DIContainer not available for PostalCodeInputField")
            return
        }

        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }

    private func validatePostalCode() {
        guard let validationService = validationService else { return }

        // Use PostalCodeRule with country code
        let postalCodeRule = PostalCodeRule(countryCode: countryCode)
        let result = postalCodeRule.validate(postalCode)

        isValid = result.isValid
        errorMessage = result.errors.first?.message
        onValidationChange?(result.isValid)
    }
}
