//
//  CVVInputField.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

/// A SwiftUI component for credit card CVV input with validation based on card network.
@available(iOS 15.0, *)
struct CVVInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String?

    /// Placeholder text for the input field
    let placeholder: String

    /// The card form scope for state management
    let scope: any PrimerCardFormScope

    /// The card network to validate against (determines CVV length requirements)
    let cardNetwork: CardNetwork

    /// Optional styling configuration for customizing field appearance
    let styling: PrimerFieldStyling?

    // MARK: - Private Properties

    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?

    /// The CVV entered by the user
    @State private var cvv: String = ""

    /// The validation state of the CVV
    @State private var isValid: Bool = false

    /// Error message if validation fails
    @State private var errorMessage: String?

    /// Focus state for input field styling
    @State private var isFocused: Bool = false

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    /// Creates a new CVVInputField with comprehensive customization support
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
