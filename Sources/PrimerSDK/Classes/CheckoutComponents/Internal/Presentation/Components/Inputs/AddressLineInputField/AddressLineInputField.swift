//
//  AddressLineInputField.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

/// A SwiftUI component for address line input with validation and consistent styling
/// matching the card form field validation timing patterns.
@available(iOS 15.0, *)
struct AddressLineInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String?

    /// Placeholder text for the input field
    let placeholder: String

    /// Whether this field is required
    let isRequired: Bool

    /// The input element type for validation
    let inputType: PrimerInputElementType

    /// The card form scope for state management
    let scope: (any PrimerCardFormScope)?

    /// Callback when the address line changes
    let onAddressChange: ((String) -> Void)?

    /// Callback when the validation state changes
    let onValidationChange: ((Bool) -> Void)?

    /// Optional styling configuration for customizing field appearance
    let styling: PrimerFieldStyling?
    // MARK: - Private Properties

    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?

    /// The address line entered by the user
    @State private var addressLine: String = ""

    /// The validation state
    @State private var isValid: Bool = false

    /// Error message if validation fails
    @State private var errorMessage: String?

    /// Focus state for input field styling
    @State private var isFocused: Bool = false

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    /// Creates a new AddressLineInputField with comprehensive customization support (scope-based)
    init(
        label: String?,
        placeholder: String,
        isRequired: Bool,
        inputType: PrimerInputElementType,
        scope: any PrimerCardFormScope,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.inputType = inputType
        self.scope = scope
        self.styling = styling
        self.onAddressChange = nil
        self.onValidationChange = nil
    }

    /// Creates a new AddressLineInputField with comprehensive customization support (callback-based)
    init(
        label: String?,
        placeholder: String,
        isRequired: Bool,
        inputType: PrimerInputElementType,
        styling: PrimerFieldStyling? = nil,
        onAddressChange: ((String) -> Void)? = nil,
        onValidationChange: ((Bool) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.inputType = inputType
        self.scope = nil
        self.styling = styling
        self.onAddressChange = onAddressChange
        self.onValidationChange = onValidationChange
    }

    // MARK: - Body

    var body: some View {
        PrimerInputFieldContainer(
            label: label,
            styling: styling,
            text: $addressLine,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused
        ) {
            if let validationService {
                AddressLineTextField(
                    addressLine: $addressLine,
                    isValid: $isValid,
                    errorMessage: $errorMessage,
                    isFocused: $isFocused,
                    placeholder: placeholder,
                    isRequired: isRequired,
                    inputType: inputType,
                    styling: styling,
                    validationService: validationService,
                    scope: scope,
                    onAddressChange: onAddressChange,
                    onValidationChange: onValidationChange,
                    tokens: tokens
                )
            } else {
                // Fallback view while loading validation service
                TextField(placeholder, text: $addressLine)
                    .autocapitalization(.words)
                    .disabled(true)            }
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
}

#if DEBUG
// MARK: - Preview
@available(iOS 15.0, *)
#Preview("Light Mode") {
    AddressLineInputField(
        label: "Address Line 1",
        placeholder: "Street address",
        isRequired: true,
        inputType: .addressLine1,
        scope: MockCardFormScope()
    )
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
}

@available(iOS 15.0, *)
#Preview("Dark Mode") {
    AddressLineInputField(
        label: "Address Line 1",
        placeholder: "Street address",
        isRequired: true,
        inputType: .addressLine1,
        scope: MockCardFormScope()
    )
    .padding()
    .background(Color.black)
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
}
#endif
