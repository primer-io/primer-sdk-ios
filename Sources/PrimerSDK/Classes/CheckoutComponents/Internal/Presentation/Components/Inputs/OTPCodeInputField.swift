//
//  OTPCodeInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// A SwiftUI component for OTP code input with validation
@available(iOS 15.0, *)
internal struct OTPCodeInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String

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

    @Environment(\.designTokens) private var tokens
    // MARK: - Computed Properties

    /// Dynamic border color based on field state
    private var borderColor: Color {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            return tokens?.primerColorBorderOutlinedError ?? .red
        } else {
            return tokens?.primerColorBorderOutlinedDefault ?? Color(FigmaDesignConstants.inputFieldBorderColor)
        }
    }

    // MARK: - Initialization

    /// Creates a new OTPCodeInputField with comprehensive customization support (scope-based)
    internal init(
        label: String,
        placeholder: String,
        scope: any PrimerCardFormScope,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.expectedLength = 6 // Default OTP length
        self.scope = scope
        self.onOTPCodeChange = nil
        self.onValidationChange = nil
    }

    /// Creates a new OTPCodeInputField with comprehensive customization support (callback-based)
    internal init(
        label: String,
        placeholder: String,
        expectedLength: Int,
        onOTPCodeChange: ((String) -> Void)? = nil,
        onValidationChange: ((Bool) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.expectedLength = expectedLength
        self.scope = nil
        self.onOTPCodeChange = onOTPCodeChange
        self.onValidationChange = onValidationChange
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: tokens?.primerSpaceXsmall ?? 4) {
            // Label
            Text(label)
                .font(tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .caption)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)

            // OTP input field
            TextField(placeholder, text: $otpCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .padding(tokens?.primerSpaceMedium ?? 12)
                .background(
                    Group {
                        if true {
                            // Only apply manual background when no gradient is present
                            tokens?.primerColorBackground ?? .white
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: FigmaDesignConstants.inputFieldRadius)
                        .stroke(borderColor, lineWidth: 1)
                )
                .cornerRadius(FigmaDesignConstants.inputFieldRadius)
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

            // Error message (always reserve space to prevent height changes)
            Text(errorMessage ?? " ")
                .font(tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .caption)
                .foregroundColor(tokens?.primerColorTextNegative ?? .red)
                .padding(.top, tokens?.primerSpaceXsmall ?? 2)
                .opacity(errorMessage != nil ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: errorMessage != nil)
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

    private func validateOTPCode() {
        guard let validationService = validationService else { return }

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
