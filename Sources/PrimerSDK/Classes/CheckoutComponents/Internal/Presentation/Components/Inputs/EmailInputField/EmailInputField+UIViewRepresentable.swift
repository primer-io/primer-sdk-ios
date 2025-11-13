//
//  EmailInputField+UIViewRepresentable.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// UIViewRepresentable wrapper for email input with focus-based validation
@available(iOS 15.0, *)
struct EmailTextField: UIViewRepresentable {
    // MARK: - Properties

    @Binding var email: String
    @Binding var isValid: Bool
    @Binding var errorMessage: String?
    @Binding var isFocused: Bool
    
    let placeholder: String
    let styling: PrimerFieldStyling?
    let validationService: ValidationService
    let scope: (any PrimerCardFormScope)?
    let onEmailChange: ((String) -> Void)?
    let onValidationChange: ((Bool) -> Void)?
    let tokens: DesignTokens?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.configurePrimerStyle(
            placeholder: placeholder,
            configuration: .email,
            styling: styling,
            tokens: tokens,
            doneButtonTarget: context.coordinator,
            doneButtonAction: #selector(Coordinator.doneButtonTapped)
        )
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        if textField.text != email {
            textField.text = email
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            email: $email,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            scope: scope,
            onEmailChange: onEmailChange,
            onValidationChange: onValidationChange
        )
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        // MARK: - Properties

        @Binding private var email: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let validationService: ValidationService
        private let scope: (any PrimerCardFormScope)?
        private let onEmailChange: ((String) -> Void)?
        private let onValidationChange: ((Bool) -> Void)?

        init(
            validationService: ValidationService,
            email: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            scope: (any PrimerCardFormScope)?,
            onEmailChange: ((String) -> Void)?,
            onValidationChange: ((Bool) -> Void)?
        ) {
            self.validationService = validationService
            self._email = email
            self._isValid = isValid
            self._errorMessage = errorMessage
            self._isFocused = isFocused
            self.scope = scope
            self.onEmailChange = onEmailChange
            self.onValidationChange = onValidationChange
        }

        @objc func doneButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = true
                self.errorMessage = nil
                self.scope?.clearFieldError(.email)
                // Don't set isValid = false immediately - let validation happen on text change or focus loss
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = false
            }
            validateEmail()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = email
            email = currentText.replacingCharacters(in: range, with: string)
            if let scope {
                scope.updateEmail(email)
            } else {
                onEmailChange?(email)
            }
            isValid = !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && email.contains("@")
            scope?.updateValidationStateIfNeeded(for: .email, isValid: isValid)
            return false
        }

        private func validateEmail() {
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedEmail.isEmpty {
                isValid = false
                errorMessage = nil
                onValidationChange?(false)
                return
            }
            let result = validationService.validate(
                input: email,
                with: EmailRule()
            )
            isValid = result.isValid
            errorMessage = result.errorMessage
            onValidationChange?(result.isValid)
            if let scope {
                if result.isValid {
                    scope.clearFieldError(.email)
                } else if let message = result.errorMessage {
                    scope.setFieldError(.email, message: message, errorCode: result.errorCode)
                }
            }
        }
    }
}
