//
//  PostalCodeInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import UIKit

/// A SwiftUI component for postal code input with validation and consistent styling
/// matching the card form field validation timing patterns.
@available(iOS 15.0, *)
struct PostalCodeInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String?

    /// Placeholder text for the input field
    let placeholder: String

    /// Country code for validation (optional)
    let countryCode: String?

    /// The card form scope for state management
    let scope: any PrimerCardFormScope

    /// Optional styling configuration for customizing field appearance
    let styling: PrimerFieldStyling?
    // MARK: - Private Properties

    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?

    /// The postal code entered by the user
    @State private var postalCode: String = ""

    /// The validation state of the postal code
    @State private var isValid: Bool = false

    /// Error message if validation fails
    @State private var errorMessage: String?

    /// Focus state for input field styling
    @State private var isFocused: Bool = false

    @Environment(\.designTokens) private var tokens

    // MARK: - Computed Properties

    /// Country-specific keyboard type
    private var keyboardTypeForCountry: UIKeyboardType {
        // US ZIP codes are numeric
        if countryCode == "US" {
            return .numberPad
        }
        // Default to alphanumeric for other countries
        return .default
    }

    // MARK: - Initialization

    /// Creates a new PostalCodeInputField with comprehensive customization support
    init(
        label: String?,
        placeholder: String,
        countryCode: String? = nil,
        scope: any PrimerCardFormScope,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.countryCode = countryCode
        self.scope = scope
        self.styling = styling
    }

    // MARK: - Body

    var body: some View {
        PrimerInputFieldContainer(
            label: label,
            styling: styling,
            text: $postalCode,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused
        ) {
            if let validationService = validationService {
                PostalCodeTextField(
                    postalCode: $postalCode,
                    isValid: $isValid,
                    errorMessage: $errorMessage,
                    isFocused: $isFocused,
                    placeholder: placeholder,
                    countryCode: countryCode,
                    keyboardType: keyboardTypeForCountry,
                    styling: styling,
                    validationService: validationService,
                    scope: scope,
                    tokens: tokens
                )
            } else {
                // Fallback view while loading validation service
                TextField(placeholder, text: $postalCode)
                    .keyboardType(keyboardTypeForCountry)
                    .autocapitalization(.allCharacters)
                    .disabled(true)
            }
        }
        .onAppear {
            setupValidationService()
        }
    }

    private func setupValidationService() {
        guard let container = container else {
            logger.error(message: "DIContainer not available for PostalCodeInputField")
            return
        }

        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }
}

/// UIViewRepresentable wrapper for postal code input with focus-based validation
@available(iOS 15.0, *)
private struct PostalCodeTextField: UIViewRepresentable, LogReporter {
    @Binding var postalCode: String
    @Binding var isValid: Bool
    @Binding var errorMessage: String?
    @Binding var isFocused: Bool
    let placeholder: String
    let countryCode: String?
    let keyboardType: UIKeyboardType
    let styling: PrimerFieldStyling?
    let validationService: ValidationService
    let scope: any PrimerCardFormScope
    let tokens: DesignTokens?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator

        // Create custom configuration with dynamic keyboard type
        let configuration = PrimerTextFieldConfiguration(
            keyboardType: keyboardType,
            autocapitalizationType: .allCharacters,
            autocorrectionType: .no,
            textContentType: nil,
            returnKeyType: .done,
            isSecureTextEntry: false
        )

        textField.configurePrimerStyle(
            placeholder: placeholder,
            configuration: configuration,
            styling: styling,
            tokens: tokens,
            doneButtonTarget: context.coordinator,
            doneButtonAction: #selector(Coordinator.doneButtonTapped)
        )

        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        if textField.text != postalCode {
            textField.text = postalCode
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            postalCode: $postalCode,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            countryCode: countryCode,
            scope: scope
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        private let validationService: ValidationService
        @Binding private var postalCode: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let countryCode: String?
        private let scope: any PrimerCardFormScope

        init(
            validationService: ValidationService,
            postalCode: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            countryCode: String?,
            scope: any PrimerCardFormScope
        ) {
            self.validationService = validationService
            self._postalCode = postalCode
            self._isValid = isValid
            self._errorMessage = errorMessage
            self._isFocused = isFocused
            self.countryCode = countryCode
            self.scope = scope
        }

        @objc func doneButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = true
                self.errorMessage = nil
                self.scope.clearFieldError(.postalCode)
                // Don't set isValid = false immediately - let validation happen on text change or focus loss
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = false
            }
            validatePostalCode()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Get current text
            let currentText = postalCode

            // Create new text
            guard let textRange = Range(range, in: currentText) else { return false }
            let newText = currentText.replacingCharacters(in: textRange, with: string)

            // Update state
            postalCode = newText
            scope.updatePostalCode(newText)

            // Simple validation while typing (don't show errors until focus loss)
            isValid = !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            // Update scope validation state while typing
            if let scope = scope as? DefaultCardFormScope {
                scope.updatePostalCodeValidationState(isValid)
            }

            return false
        }

        private func validatePostalCode() {
            let trimmedPostalCode = postalCode.trimmingCharacters(in: .whitespacesAndNewlines)

            // Empty field handling - don't show errors for empty fields
            if trimmedPostalCode.isEmpty {
                isValid = false // Postal code is required
                errorMessage = nil // Never show error message for empty fields
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updatePostalCodeValidationState(false)
                }
                return
            }

            let result = validationService.validate(
                input: postalCode,
                with: PostalCodeRule(countryCode: countryCode)
            )

            isValid = result.isValid
            errorMessage = result.errorMessage

            // Update scope state based on validation
            if result.isValid {
                scope.clearFieldError(.postalCode)
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updatePostalCodeValidationState(true)
                }
            } else if let message = result.errorMessage {
                scope.setFieldError(.postalCode, message: message, errorCode: result.errorCode)
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updatePostalCodeValidationState(false)
                }
            }
        }
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 15.0, *)
struct PostalCodeInputField_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode
            VStack(spacing: 16) {
                // Default state
                PostalCodeInputField(
                    label: "Postal Code",
                    placeholder: "Enter postal code",
                    scope: MockCardFormScope()
                )
                .background(Color.gray.opacity(0.1))

                // No label
                PostalCodeInputField(
                    label: nil,
                    placeholder: "Postal Code",
                    scope: MockCardFormScope()
                )
                .background(Color.gray.opacity(0.1))

                // Error state
                PostalCodeInputField(
                    label: "Postal Code with Error",
                    placeholder: "Enter valid code",
                    scope: MockCardFormScope(isValid: false)
                )
                .environment(\.diContainer, MockDIContainer(
                    validationService: MockValidationService(
                        shouldFailValidation: true,
                        errorMessage: "Please enter a valid postal code"
                    )
                ))
                .background(Color.gray.opacity(0.1))
            }
            .padding()
            .environment(\.designTokens, MockDesignTokens.light)
            .environment(\.diContainer, MockDIContainer())
            .previewDisplayName("Light Mode")

            // Dark mode
            VStack(spacing: 16) {
                // Default state
                PostalCodeInputField(
                    label: "Postal Code",
                    placeholder: "Enter postal code",
                    scope: MockCardFormScope()
                )
                .background(Color.gray.opacity(0.1))

                // No label
                PostalCodeInputField(
                    label: nil,
                    placeholder: "Postal Code",
                    scope: MockCardFormScope()
                )
                .background(Color.gray.opacity(0.1))

                // Error state
                PostalCodeInputField(
                    label: "Postal Code with Error",
                    placeholder: "Enter valid code",
                    scope: MockCardFormScope(isValid: false)
                )
                .environment(\.diContainer, MockDIContainer(
                    validationService: MockValidationService(
                        shouldFailValidation: true,
                        errorMessage: "Please enter a valid postal code"
                    )
                ))
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
