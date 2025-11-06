//
//  NameInputField.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

/// A SwiftUI component for first/last name input with validation and consistent styling
/// matching the card form field validation timing patterns.
@available(iOS 15.0, *)
struct NameInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String?

    /// Placeholder text for the input field
    let placeholder: String

    /// The input element type for validation
    let inputType: PrimerInputElementType

    /// The card form scope for state management
    let scope: (any PrimerCardFormScope)?

    /// Callback when the name changes
    let onNameChange: ((String) -> Void)?

    /// Callback when the validation state changes
    let onValidationChange: ((Bool) -> Void)?

    /// Optional styling configuration for customizing field appearance
    let styling: PrimerFieldStyling?
    // MARK: - Private Properties

    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?

    /// The name entered by the user
    @State private var name: String = ""

    /// The validation state of the name
    @State private var isValid: Bool = false

    /// Error message if validation fails
    @State private var errorMessage: String?

    /// Focus state for input field styling
    @State private var isFocused: Bool = false

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    /// Creates a new NameInputField with comprehensive customization support (scope-based)
    init(
        label: String?,
        placeholder: String,
        inputType: PrimerInputElementType,
        scope: any PrimerCardFormScope,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.inputType = inputType
        self.scope = scope
        self.styling = styling
        self.onNameChange = nil
        self.onValidationChange = nil
    }

    /// Creates a new NameInputField with comprehensive customization support (callback-based)
    init(
        label: String?,
        placeholder: String,
        inputType: PrimerInputElementType,
        styling: PrimerFieldStyling? = nil,
        onNameChange: ((String) -> Void)? = nil,
        onValidationChange: ((Bool) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.inputType = inputType
        self.scope = nil
        self.styling = styling
        self.onNameChange = onNameChange
        self.onValidationChange = onValidationChange
    }

    // MARK: - Body

    var body: some View {
        PrimerInputFieldContainer(
            label: label,
            styling: styling,
            text: $name,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused
        ) {
            if let validationService {
                NameTextField(
                    name: $name,
                    isValid: $isValid,
                    errorMessage: $errorMessage,
                    isFocused: $isFocused,
                    placeholder: placeholder,
                    inputType: inputType,
                    styling: styling,
                    validationService: validationService,
                    scope: scope,
                    onNameChange: onNameChange,
                    onValidationChange: onValidationChange,
                    tokens: tokens
                )
            } else {
                // Fallback view while loading validation service
                TextField(placeholder, text: $name)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                    .disabled(true)
            }
        }
        .onAppear {
            setupValidationService()
        }
    }

    private func setupValidationService() {
        guard let container = container else {
            logger.error(message: "DIContainer not available for NameInputField")
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
    NameInputField(
        label: "First Name",
        placeholder: "Jane",
        inputType: .firstName,
        scope: MockCardFormScope()
    )
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
}

@available(iOS 15.0, *)
#Preview("Dark Mode") {
    NameInputField(
        label: "First Name",
        placeholder: "Jane",
        inputType: .firstName,
        scope: MockCardFormScope()
    )
    .padding()
    .background(Color.black)
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
}
#endif
