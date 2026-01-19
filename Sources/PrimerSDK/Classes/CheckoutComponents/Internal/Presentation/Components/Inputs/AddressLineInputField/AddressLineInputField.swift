//
//  AddressLineInputField.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct AddressLineInputField: View, LogReporter {
    // MARK: - Public Properties

    let label: String?
    let placeholder: String
    let isRequired: Bool
    let inputType: PrimerInputElementType
    let scope: (any PrimerCardFormScope)?
    let onAddressChange: ((String) -> Void)?
    let onValidationChange: ((Bool) -> Void)?
    let styling: PrimerFieldStyling?

    // MARK: - Private Properties

    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?
    @State private var addressLine: String = ""
    @State private var isValid: Bool = false
    @State private var errorMessage: String?
    @State private var isFocused: Bool = false

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

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
            if let validationService = validationService {
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
