//
//  PostalCodeInputField+UIViewRepresentable.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

/// UIViewRepresentable wrapper for postal code input with focus-based validation
@available(iOS 15.0, *)
struct PostalCodeTextField: UIViewRepresentable, LogReporter {
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
