//
//  EmailInputField.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// A SwiftUI component for email input with validation and consistent styling
/// matching the card form field validation timing patterns.
@available(iOS 15.0, *)
struct EmailInputField: View, LogReporter {
    // MARK: - Properties

    let label: String?
    let placeholder: String
    let scope: (any PrimerCardFormScope)?
    let onEmailChange: ((String) -> Void)?
    let onValidationChange: ((Bool) -> Void)?
    let styling: PrimerFieldStyling?

    // MARK: - Private Properties

    @State private var validationService: ValidationService?
    @State private var email: String = ""
    @State private var isValid: Bool = false
    @State private var errorMessage: String?
    @State private var isFocused: Bool = false
    @Environment(\.diContainer) private var container
    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    init(
        label: String?,
        placeholder: String,
        scope: any PrimerCardFormScope,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.scope = scope
        self.styling = styling
        onEmailChange = nil
        onValidationChange = nil
    }

    init(
        label: String?,
        placeholder: String,
        styling: PrimerFieldStyling? = nil,
        onEmailChange: ((String) -> Void)? = nil,
        onValidationChange: ((Bool) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        scope = nil
        self.styling = styling
        self.onEmailChange = onEmailChange
        self.onValidationChange = onValidationChange
    }

    // MARK: - Body

    var body: some View {
        PrimerInputFieldContainer(
            label: label,
            styling: styling,
            text: $email,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused
        ) {
            if let validationService {
                EmailTextField(
                    email: $email,
                    isValid: $isValid,
                    errorMessage: $errorMessage,
                    isFocused: $isFocused,
                    placeholder: placeholder,
                    styling: styling,
                    validationService: validationService,
                    scope: scope,
                    onEmailChange: onEmailChange,
                    onValidationChange: onValidationChange,
                    tokens: tokens
                )
            } else {
                // Fallback view while loading validation service
                TextField(placeholder, text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textContentType(.emailAddress)
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
            return logger.error(message: "DIContainer not available for EmailInputField")
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
    EmailInputField(
        label: "Email Address",
        placeholder: "Enter your email",
        scope: MockCardFormScope()
    )
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
}

@available(iOS 15.0, *)
#Preview("Dark Mode") {
    EmailInputField(
        label: "Email Address",
        placeholder: "Enter your email",
        scope: MockCardFormScope()
    )
    .padding()
    .background(Color.black)
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
}
#endif
