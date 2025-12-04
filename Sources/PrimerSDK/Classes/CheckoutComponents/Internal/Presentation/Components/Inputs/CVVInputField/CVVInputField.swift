//
//  CVVInputField.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct CVVInputField: View, LogReporter {
    // MARK: - Public Properties

    let label: String?
    let placeholder: String
    let scope: any PrimerCardFormScope
    let cardNetwork: CardNetwork
    let styling: PrimerFieldStyling?

    // MARK: - Private Properties

    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?
    @State private var cvv: String = ""
    @State private var isValid: Bool = false
    @State private var errorMessage: String?
    @State private var isFocused: Bool = false
    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    init(
        label: String?,
        placeholder: String,
        scope: any PrimerCardFormScope,
        cardNetwork: CardNetwork,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.scope = scope
        self.cardNetwork = cardNetwork
        self.styling = styling
    }

    // MARK: - Body

    var body: some View {
        PrimerInputFieldContainer(
            label: label,
            styling: styling,
            text: $cvv,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused
        ) {
            if let validationService = validationService {
                CVVTextField(
                    cvv: $cvv,
                    isValid: $isValid,
                    errorMessage: $errorMessage,
                    isFocused: $isFocused,
                    placeholder: placeholder,
                    cardNetwork: cardNetwork,
                    styling: styling,
                    validationService: validationService,
                    scope: scope,
                    tokens: tokens
                )
            } else {
                // Fallback view while loading validation service
                TextField(placeholder, text: $cvv)
                    .keyboardType(.numberPad)
                    .disabled(true)
            }
        }
        .accessibility(config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.CardForm.cvcField,
            label: CheckoutComponentsStrings.a11yCVCLabel,
            hint: CheckoutComponentsStrings.a11yCVCHint,
            value: errorMessage,
            traits: []
        ))
        .onAppear {
            setupValidationService()
        }
    }

    private func setupValidationService() {
        guard let container = container else {
            logger.error(message: "DIContainer not available for CVVInputField")
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
        CVVInputField(
            label: "CVV",
            placeholder: "123",
            scope: MockCardFormScope(),
            cardNetwork: .visa
        )
        .padding()
        .environment(\.designTokens, MockDesignTokens.light)
        .environment(\.diContainer, MockDIContainer())
    }

    @available(iOS 15.0, *)
    #Preview("Dark Mode") {
        CVVInputField(
            label: "CVV",
            placeholder: "123",
            scope: MockCardFormScope(),
            cardNetwork: .visa
        )
        .padding()
        .background(Color.black)
        .environment(\.designTokens, MockDesignTokens.dark)
        .environment(\.diContainer, MockDIContainer())
        .preferredColorScheme(.dark)
    }
#endif
