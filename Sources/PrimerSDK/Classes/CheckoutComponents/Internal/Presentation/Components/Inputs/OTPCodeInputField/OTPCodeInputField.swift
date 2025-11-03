//
//  OTPCodeInputField.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// A SwiftUI component for OTP code input with validation
@available(iOS 15.0, *)
struct OTPCodeInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String?

    /// Placeholder text for the input field
    let placeholder: String

    /// Expected length of the OTP code
    let expectedLength: Int

    /// The card form scope for state management
    let scope: (any PrimerCardFormScope)?

    /// Callback when the OTP code changes
    let onOTPCodeChange: ((String) -> Void)?

    /// Callback when the validation state changes
    let onValidationChange: ((Bool) -> Void)?

    /// Optional styling configuration for customizing field appearance
    let styling: PrimerFieldStyling?

    // MARK: - Private Properties

    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?

    /// The OTP code entered by the user
    @State private var otpCode: String = ""

    /// The validation state of the OTP code
    @State private var isValid: Bool = false

    /// Error message if validation fails
    @State private var errorMessage: String?

    /// Focus state for input field styling
    @State private var isFocused: Bool = false

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    /// Creates a new OTPCodeInputField with comprehensive customization support (scope-based)
    init(
        label: String?,
        placeholder: String,
        scope: any PrimerCardFormScope,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.expectedLength = 6 // Default OTP length
        self.scope = scope
        self.styling = styling
        self.onOTPCodeChange = nil
        self.onValidationChange = nil
    }

    /// Creates a new OTPCodeInputField with comprehensive customization support (callback-based)
    init(
        label: String?,
        placeholder: String,
        expectedLength: Int,
        styling: PrimerFieldStyling? = nil,
        onOTPCodeChange: ((String) -> Void)? = nil,
        onValidationChange: ((Bool) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.expectedLength = expectedLength
        self.scope = nil
        self.styling = styling
        self.onOTPCodeChange = onOTPCodeChange
        self.onValidationChange = onValidationChange
    }

    // MARK: - Body

    var body: some View {
        PrimerInputFieldContainer(
            label: label,
            styling: styling,
            text: $otpCode,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused
        ) {
            TextField(
                "",
                text: $otpCode,
                prompt: Text(placeholder)
                    .font(styling?.font ?? PrimerFont.bodyLarge(tokens: tokens))
                    .foregroundColor(styling?.placeholderColor ?? PrimerCheckoutColors.textPlaceholder(tokens: tokens))
            )
            .font(styling?.font ?? PrimerFont.bodyLarge(tokens: tokens))
            .foregroundColor(styling?.textColor ?? PrimerCheckoutColors.textPrimary(tokens: tokens))
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .frame(height: PrimerSize.xxlarge(tokens: tokens))
            .onChange(of: otpCode) { newValue in
                // Limit to expected length
                if newValue.count > expectedLength {
                    otpCode = String(newValue.prefix(expectedLength))
                } else {
                    if let scope = scope {
                        scope.updateOtpCode(newValue)
                    } else {
                        onOTPCodeChange?(newValue)
                    }
                    validateOTPCode()
                }
            }
        }
        .onAppear {
            setupValidationService()
        }
    }

    private func setupValidationService() {
        guard let container = container else {
            logger.error(message: "DIContainer not available for OTPCodeInputField")
            return
        }

        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }

    @MainActor
    private func validateOTPCode() {
        // Use OTPCodeRule with expected length
        let otpRule = OTPCodeRule(expectedLength: expectedLength)
        let result = otpRule.validate(otpCode)

        isValid = result.isValid
        errorMessage = result.errorMessage
        onValidationChange?(result.isValid)

        // Update scope state based on validation
        if let scope = scope {
            if result.isValid {
                scope.clearFieldError(.otp)
            } else if let message = result.errorMessage {
                scope.setFieldError(.otp, message: message, errorCode: result.errorCode)
            }
        }
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 15.0, *)
#Preview("Light Mode") {
    OTPCodeInputField(
        label: "Enter OTP Code",
        placeholder: "000000",
        scope: MockCardFormScope()
    )
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
}

@available(iOS 15.0, *)
#Preview("Dark Mode") {
    OTPCodeInputField(
        label: "Enter OTP Code",
        placeholder: "000000",
        scope: MockCardFormScope()
    )
    .padding()
    .background(Color.black)
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
}
#endif
