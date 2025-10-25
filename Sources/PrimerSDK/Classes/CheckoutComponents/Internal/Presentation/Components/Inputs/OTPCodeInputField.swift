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
            return PrimerCheckoutColors.borderError(tokens: tokens)
        } else {
            return PrimerCheckoutColors.borderDefault(tokens: tokens)
        }
    }

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
        self.onOTPCodeChange = nil
        self.onValidationChange = nil
    }

    /// Creates a new OTPCodeInputField with comprehensive customization support (callback-based)
    init(
        label: String?,
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
        VStack(alignment: .leading, spacing: PrimerSpacing.xsmall(tokens: tokens)) {
            // Label
            if let label = label {
                Text(label)
                    .font(PrimerFont.bodySmall(tokens: tokens))
                    .foregroundColor(PrimerCheckoutColors.textSecondary(tokens: tokens))
            }

            // OTP input field
            TextField(placeholder, text: $otpCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .padding(PrimerSpacing.medium(tokens: tokens))
                .primerInputFieldBorder(
                    cornerRadius: PrimerRadius.small(tokens: tokens),
                    backgroundColor: PrimerCheckoutColors.background(tokens: tokens),
                    borderColor: borderColor,
                    borderWidth: PrimerBorderWidth.standard
                )
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
                .font(PrimerFont.bodySmall(tokens: tokens))
                .foregroundColor(PrimerCheckoutColors.textNegative(tokens: tokens))
                .padding(.top, PrimerSpacing.xsmall(tokens: tokens) / 2)
                .opacity(errorMessage != nil ? 1.0 : 0.0)
                .animation(AnimationConstants.errorAnimation, value: errorMessage != nil)
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
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - Basic States
                Group {
                    Text("Basic States")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Default empty state (scope-based)
                    OTPCodeInputField(
                        label: "Enter OTP Code",
                        placeholder: "000000",
                        scope: MockCardFormScope()
                    )
                    .background(Color.gray.opacity(0.1))

                    // No label (callback-based)
                    OTPCodeInputField(
                        label: nil,
                        placeholder: "Enter code",
                        expectedLength: 6,
                        onOTPCodeChange: { code in
                            print("OTP changed: \(code)")
                        },
                        onValidationChange: { isValid in
                            print("Validation: \(isValid)")
                        }
                    )
                    .background(Color.gray.opacity(0.1))
                }

                Divider()

                // MARK: - OTP Length Examples
                Group {
                    Text("OTP Length Examples")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // 6-digit OTP (most common)
                    OTPCodeInputField(
                        label: "6-Digit OTP",
                        placeholder: "000000",
                        expectedLength: 6
                    )
                    .background(Color.gray.opacity(0.1))

                    // 4-digit OTP (banking/short codes)
                    OTPCodeInputField(
                        label: "4-Digit OTP",
                        placeholder: "0000",
                        expectedLength: 4
                    )
                    .background(Color.gray.opacity(0.1))

                    // 8-digit OTP (high security)
                    OTPCodeInputField(
                        label: "8-Digit OTP",
                        placeholder: "00000000",
                        expectedLength: 8
                    )
                    .background(Color.gray.opacity(0.1))

                    // 5-digit OTP (custom)
                    OTPCodeInputField(
                        label: "5-Digit OTP",
                        placeholder: "00000",
                        expectedLength: 5
                    )
                    .background(Color.gray.opacity(0.1))
                }

                Divider()

                // MARK: - Use Case Examples
                Group {
                    Text("Use Case Examples")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Email verification
                    OTPCodeInputField(
                        label: "Email Verification Code",
                        placeholder: "Enter 6-digit code from email",
                        expectedLength: 6
                    )
                    .background(Color.gray.opacity(0.1))

                    // SMS verification
                    OTPCodeInputField(
                        label: "SMS Verification",
                        placeholder: "Enter code from SMS",
                        expectedLength: 6
                    )
                    .background(Color.gray.opacity(0.1))

                    // Two-factor authentication
                    OTPCodeInputField(
                        label: "Two-Factor Authentication",
                        placeholder: "Enter 2FA code",
                        expectedLength: 6
                    )
                    .background(Color.gray.opacity(0.1))

                    // Payment verification
                    OTPCodeInputField(
                        label: "Payment Verification",
                        placeholder: "Enter code to confirm payment",
                        expectedLength: 6
                    )
                    .background(Color.gray.opacity(0.1))
                }

                Divider()

                // MARK: - Validation States
                Group {
                    Text("Validation States")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Valid state (callback-based with validation feedback)
                    OTPCodeInputField(
                        label: "Valid OTP",
                        placeholder: "123456",
                        expectedLength: 6,
                        onOTPCodeChange: { _ in },
                        onValidationChange: { isValid in
                            print("Valid: \(isValid)")
                        }
                    )
                    .background(Color.gray.opacity(0.1))

                    // Invalid state (scope-based)
                    OTPCodeInputField(
                        label: "Invalid OTP",
                        placeholder: "Enter valid code",
                        scope: MockCardFormScope(isValid: false)
                    )
                    .background(Color.gray.opacity(0.1))

                    // Partial entry state
                    OTPCodeInputField(
                        label: "Partial Entry",
                        placeholder: "123...",
                        expectedLength: 6
                    )
                    .background(Color.gray.opacity(0.1))
                }

                Divider()

                // MARK: - Label Variations
                Group {
                    Text("Label Variations")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    OTPCodeInputField(
                        label: "Verification Code",
                        placeholder: "000000",
                        expectedLength: 6
                    )
                    .background(Color.gray.opacity(0.1))

                    OTPCodeInputField(
                        label: "One-Time Password",
                        placeholder: "Enter OTP",
                        expectedLength: 6
                    )
                    .background(Color.gray.opacity(0.1))

                    OTPCodeInputField(
                        label: "Security Code",
                        placeholder: "######",
                        expectedLength: 6
                    )
                    .background(Color.gray.opacity(0.1))

                    OTPCodeInputField(
                        label: "Authentication Code",
                        placeholder: "Code from authenticator app",
                        expectedLength: 6
                    )
                    .background(Color.gray.opacity(0.1))
                }

                Divider()

                // MARK: - Placeholder Variations
                Group {
                    Text("Placeholder Variations")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    OTPCodeInputField(
                        label: "OTP Code",
                        placeholder: "000000",
                        expectedLength: 6
                    )
                    .background(Color.gray.opacity(0.1))

                    OTPCodeInputField(
                        label: "OTP Code",
                        placeholder: "######",
                        expectedLength: 6
                    )
                    .background(Color.gray.opacity(0.1))

                    OTPCodeInputField(
                        label: "OTP Code",
                        placeholder: "Enter 6-digit code",
                        expectedLength: 6
                    )
                    .background(Color.gray.opacity(0.1))

                    OTPCodeInputField(
                        label: "OTP Code",
                        placeholder: "_ _ _ _ _ _",
                        expectedLength: 6
                    )
                    .background(Color.gray.opacity(0.1))
                }
            }
            .padding()
        }
        .environment(\.designTokens, nil)
        .environment(\.diContainer, nil)
        .previewDisplayName("OTP Code Input Field")
    }
}
#endif
