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
internal struct PostalCodeInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String

    /// Placeholder text for the input field
    let placeholder: String

    /// Country code for validation (optional)
    let countryCode: String?

    /// Callback when the postal code changes
    let onPostalCodeChange: ((String) -> Void)?

    /// Callback when the validation state changes
    let onValidationChange: ((Bool) -> Void)?

    /// PrimerModifier for comprehensive styling customization
    let modifier: PrimerModifier

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

    /// Dynamic border color based on field state
    private var borderColor: Color {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            return tokens?.primerColorBorderOutlinedError ?? .red
        } else if isFocused {
            return tokens?.primerColorBorderOutlinedFocus ?? .blue
        } else {
            return tokens?.primerColorBorderOutlinedDefault ?? Color(FigmaDesignConstants.inputFieldBorderColor)
        }
    }

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
    internal init(
        label: String,
        placeholder: String,
        countryCode: String? = nil,
        modifier: PrimerModifier = PrimerModifier(),
        onPostalCodeChange: ((String) -> Void)? = nil,
        onValidationChange: ((Bool) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.countryCode = countryCode
        self.modifier = modifier
        self.onPostalCodeChange = onPostalCodeChange
        self.onValidationChange = onValidationChange
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaDesignConstants.labelInputSpacing) {
            // Label
            Text(label)
                .font(tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .system(size: 12, weight: .medium))
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)

            // Postal code input field with ZStack architecture
            ZStack {
                // Background and border styling
                RoundedRectangle(cornerRadius: tokens?.primerRadiusMedium ?? 8)
                    .fill(tokens?.primerColorBackground ?? Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: tokens?.primerRadiusMedium ?? 8)
                            .stroke(borderColor, lineWidth: 1)
                            .animation(.easeInOut(duration: 0.2), value: borderColor)
                    )
                    .shadow(
                        color: Color.black.opacity(0.04),
                        radius: tokens?.primerSpaceXsmall ?? 2,
                        x: 0,
                        y: 1
                    )

                // Input field content
                HStack {
                    if let validationService = validationService {
                        PostalCodeTextField(
                            postalCode: $postalCode,
                            isValid: $isValid,
                            errorMessage: $errorMessage,
                            isFocused: $isFocused,
                            placeholder: placeholder,
                            countryCode: countryCode,
                            keyboardType: keyboardTypeForCountry,
                            validationService: validationService,
                            onPostalCodeChange: onPostalCodeChange,
                            onValidationChange: onValidationChange
                        )
                        .padding(.leading, tokens?.primerSpaceLarge ?? 16)
                        .padding(.trailing, errorMessage != nil ? (tokens?.primerSizeXxlarge ?? 60) : (tokens?.primerSpaceLarge ?? 16))
                        .padding(.vertical, tokens?.primerSpaceMedium ?? 12)
                    } else {
                        // Fallback view while loading validation service
                        TextField(placeholder, text: $postalCode)
                            .keyboardType(keyboardTypeForCountry)
                            .autocapitalization(.allCharacters)
                            .disabled(true)
                            .padding(.leading, tokens?.primerSpaceLarge ?? 16)
                            .padding(.trailing, tokens?.primerSpaceLarge ?? 16)
                            .padding(.vertical, tokens?.primerSpaceMedium ?? 12)
                    }

                    Spacer()
                }

                // Right side overlay (error icon)
                HStack {
                    Spacer()

                    if let errorMessage = errorMessage, !errorMessage.isEmpty {
                        // Error icon when validation fails
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: tokens?.primerSizeMedium ?? 20, height: tokens?.primerSizeMedium ?? 20)
                            .foregroundColor(tokens?.primerColorIconNegative ?? Color(red: 1.0, green: 0.45, blue: 0.47))
                            .padding(.trailing, tokens?.primerSpaceMedium ?? 12)
                    }
                }
            }
            .frame(height: FigmaDesignConstants.inputFieldHeight)

            // Error message (always reserve space to prevent height changes)
            Text(errorMessage ?? " ")
                .font(tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .system(size: 11, weight: .regular))
                .foregroundColor(tokens?.primerColorTextNegative ?? .red)
                .padding(.top, tokens?.primerSpaceXsmall ?? 4)
                .opacity(errorMessage != nil ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: errorMessage != nil)
        }
        .primerModifier(modifier)
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
    let validationService: ValidationService
    let onPostalCodeChange: ((String) -> Void)?
    let onValidationChange: ((Bool) -> Void)?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textField.keyboardType = keyboardType
        textField.autocapitalizationType = .allCharacters
        textField.autocorrectionType = .no
        textField.returnKeyType = .done

        // Add a "Done" button to the keyboard
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: context.coordinator, action: #selector(Coordinator.doneButtonTapped))
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar

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
            onPostalCodeChange: onPostalCodeChange,
            onValidationChange: onValidationChange
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        private let validationService: ValidationService
        @Binding private var postalCode: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let countryCode: String?
        private let onPostalCodeChange: ((String) -> Void)?
        private let onValidationChange: ((Bool) -> Void)?

        init(
            validationService: ValidationService,
            postalCode: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            countryCode: String?,
            onPostalCodeChange: ((String) -> Void)?,
            onValidationChange: ((Bool) -> Void)?
        ) {
            self.validationService = validationService
            self._postalCode = postalCode
            self._isValid = isValid
            self._errorMessage = errorMessage
            self._isFocused = isFocused
            self.countryCode = countryCode
            self.onPostalCodeChange = onPostalCodeChange
            self.onValidationChange = onValidationChange
        }

        @objc func doneButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = true
                self.errorMessage = nil
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
            onPostalCodeChange?(newText)

            // Simple validation while typing (don't show errors until focus loss)
            isValid = !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            return false
        }

        private func validatePostalCode() {
            let trimmedPostalCode = postalCode.trimmingCharacters(in: .whitespacesAndNewlines)

            // Empty field handling - don't show errors for empty fields
            if trimmedPostalCode.isEmpty {
                isValid = false // Postal code is required
                errorMessage = nil // Never show error message for empty fields
                onValidationChange?(false)
                return
            }

            let result = validationService.validate(
                input: postalCode,
                with: PostalCodeRule(countryCode: countryCode)
            )

            isValid = result.isValid
            errorMessage = result.errorMessage
            onValidationChange?(result.isValid)
        }
    }
}
