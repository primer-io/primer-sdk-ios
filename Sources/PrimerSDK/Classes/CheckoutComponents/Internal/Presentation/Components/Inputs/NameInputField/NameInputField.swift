//
//  NameInputField.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct NameInputField: View, LogReporter {
    // MARK: - Properties

    let label: String?
    let placeholder: String
    let inputType: PrimerInputElementType
    let scope: (any PrimerCardFormScope)?
    let onNameChange: ((String) -> Void)?
    let onValidationChange: ((Bool) -> Void)?
    let styling: PrimerFieldStyling?

    // MARK: - Private Properties

    @State private var validationService: ValidationService?
    @State private var name: String = ""
    @State private var isValid: Bool = false
    @State private var errorMessage: String?
    @State private var isFocused: Bool = false
    @Environment(\.diContainer) private var container
    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

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
        onNameChange = nil
        onValidationChange = nil
    }

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
        scope = nil
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

    // MARK: - Private Methods

    private func setupValidationService() {
        guard let container else {
            return logger.error(message: "DIContainer not available for NameInputField")
        }
        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }
}

#if DEBUG
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
