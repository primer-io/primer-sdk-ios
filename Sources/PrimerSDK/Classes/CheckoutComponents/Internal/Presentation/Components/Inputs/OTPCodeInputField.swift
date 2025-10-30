//
//  OTPCodeInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

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
struct OTPCodeInputField_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode
            VStack(spacing: 16) {
                // Default state (scope-based)
                OTPCodeInputField(
                    label: "Enter OTP Code",
                    placeholder: "000000",
                    scope: MockCardFormScope()
                )
                .background(Color.gray.opacity(0.1))

                // Callback-based
                OTPCodeInputField(
                    label: "Verification Code",
                    placeholder: "######",
                    expectedLength: 6,
                    onOTPCodeChange: { _ in },
                    onValidationChange: { _ in }
                )
                .background(Color.gray.opacity(0.1))

                // No label
                OTPCodeInputField(
                    label: nil,
                    placeholder: "Enter code",
                    expectedLength: 6
                )
                .background(Color.gray.opacity(0.1))
            }
            .padding()
            .environment(\.designTokens, MockDesignTokens.light)
            .environment(\.diContainer, MockDIContainer())
            .previewDisplayName("Light Mode")

            // Dark mode
            VStack(spacing: 16) {
                // Default state (scope-based)
                OTPCodeInputField(
                    label: "Enter OTP Code",
                    placeholder: "000000",
                    scope: MockCardFormScope()
                )
                .background(Color.gray.opacity(0.1))

                // Callback-based
                OTPCodeInputField(
                    label: "Verification Code",
                    placeholder: "######",
                    expectedLength: 6,
                    onOTPCodeChange: { _ in },
                    onValidationChange: { _ in }
                )
                .background(Color.gray.opacity(0.1))

                // No label
                OTPCodeInputField(
                    label: nil,
                    placeholder: "Enter code",
                    expectedLength: 6
                )
                .background(Color.gray.opacity(0.1))
            }
            .padding()
            .background(Color.black)
            .environment(\.designTokens, MockDesignTokens.dark)
            .environment(\.diContainer, MockDIContainer())
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
#endif
