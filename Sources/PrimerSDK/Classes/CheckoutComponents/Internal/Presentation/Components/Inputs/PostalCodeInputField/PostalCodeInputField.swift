//
//  PostalCodeInputField.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

/// A SwiftUI component for postal code input with validation and consistent styling
/// matching the card form field validation timing patterns.
@available(iOS 15.0, *)
struct PostalCodeInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String?

    /// Placeholder text for the input field
    let placeholder: String

    /// Country code for validation (optional)
    let countryCode: String?

    /// The card form scope for state management
    let scope: any PrimerCardFormScope

    /// Optional styling configuration for customizing field appearance
    let styling: PrimerFieldStyling?
    // MARK: - Private Properties

    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?

    /// The postal code entered by the user
    @State private var postalCode: String = ""

    /// The validation state of the postal code
    @State private var isValid: Bool = false

    /// Error message if validation fails
    @State private var errorMessage: String?

    /// Focus state for input field styling
    @State private var isFocused: Bool = false

    @Environment(\.designTokens) private var tokens

    // MARK: - Computed Properties

    /// Country-specific keyboard type
    private var keyboardTypeForCountry: UIKeyboardType {
        // US ZIP codes are numeric
        if countryCode == "US" {
            return .numberPad
        }
        // Default to alphanumeric for other countries
        return .default
    }

    // MARK: - Initialization

    /// Creates a new PostalCodeInputField with comprehensive customization support
    init(
        label: String?,
        placeholder: String,
        countryCode: String? = nil,
        scope: any PrimerCardFormScope,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.countryCode = countryCode
        self.scope = scope
        self.styling = styling
    }

    // MARK: - Body

    var body: some View {
        PrimerInputFieldContainer(
            label: label,
            styling: styling,
            text: $postalCode,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused
        ) {
            if let validationService = validationService {
                PostalCodeTextField(
                    postalCode: $postalCode,
                    isValid: $isValid,
                    errorMessage: $errorMessage,
                    isFocused: $isFocused,
                    placeholder: placeholder,
                    countryCode: countryCode,
                    keyboardType: keyboardTypeForCountry,
                    styling: styling,
                    validationService: validationService,
                    scope: scope,
                    tokens: tokens
                )
            } else {
                // Fallback view while loading validation service
                TextField(placeholder, text: $postalCode)
                    .keyboardType(keyboardTypeForCountry)
                    .autocapitalization(.allCharacters)
                    .disabled(true)
            }
        }
        .accessibility(config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.CardForm.billingAddressField("postal_code"),
            label: label ?? "Postal code",
            hint: CheckoutComponentsStrings.a11yBillingAddressPostalCodeHint,
            value: errorMessage,
            traits: []
        ))
        .onAppear {
            setupValidationService()
        }
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
}

#if DEBUG
// MARK: - Preview
@available(iOS 15.0, *)
#Preview("Light Mode") {
    PostalCodeInputField(
        label: "Postal Code",
        placeholder: "Enter postal code",
        scope: MockCardFormScope()
    )
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
}

@available(iOS 15.0, *)
#Preview("Dark Mode") {
    PostalCodeInputField(
        label: "Postal Code",
        placeholder: "Enter postal code",
        scope: MockCardFormScope()
    )
    .padding()
    .background(Color.black)
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
}
#endif
