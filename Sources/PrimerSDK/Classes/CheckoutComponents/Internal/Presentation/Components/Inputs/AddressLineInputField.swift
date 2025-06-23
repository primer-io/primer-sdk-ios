//
//  AddressLineInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// A SwiftUI component for address line input with validation
@available(iOS 15.0, *)
internal struct AddressLineInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String

    /// Placeholder text for the input field
    let placeholder: String

    /// Whether this field is required
    let isRequired: Bool

    /// The input element type for validation
    let inputType: PrimerInputElementType

    /// Callback when the address line changes
    let onAddressChange: ((String) -> Void)?

    /// Callback when the validation state changes
    let onValidationChange: ((Bool) -> Void)?

    // MARK: - Private Properties

    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?

    /// The address line entered by the user
    @State private var addressLine: String = ""

    /// The validation state
    @State private var isValid: Bool = true

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

            // Address input field
            TextField(placeholder, text: $addressLine)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.words)
                .padding()
                .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                .cornerRadius(8)
                .onChange(of: addressLine) { newValue in
                    onAddressChange?(newValue)
                    validateAddress()
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

    private func setupValidationService() {
        guard let container = container else {
            logger.error(message: "DIContainer not available for AddressLineInputField")
            return
        }

        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }

    private func validateAddress() {
        guard let validationService = validationService else { return }

        // For optional fields (like address line 2), empty is valid
        if !isRequired && addressLine.isEmpty {
            isValid = true
            errorMessage = nil
            onValidationChange?(true)
            return
        }

        let result = validationService.validate(
            input: addressLine,
            with: AddressRule()
        )

        isValid = result.isValid
        errorMessage = result.errorMessage
        onValidationChange?(result.isValid)
    }
}
