//
//  CardholderNameInputField+UIViewRepresentable.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// UIViewRepresentable wrapper for cardholder name input
@available(iOS 15.0, *)
struct CardholderNameTextField: UIViewRepresentable {
    // MARK: - Properties

    @Binding var cardholderName: String
    @Binding var isValid: Bool
    @Binding var errorMessage: String?
    @Binding var isFocused: Bool
    
    let placeholder: String
    let styling: PrimerFieldStyling?
    let validationService: ValidationService
    let scope: any PrimerCardFormScope
    let tokens: DesignTokens?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.configurePrimerStyle(
            placeholder: placeholder,
            configuration: .standard,
            styling: styling,
            tokens: tokens,
            doneButtonTarget: context.coordinator,
            doneButtonAction: #selector(Coordinator.doneButtonTapped)
        )
        textField.font = PrimerFont.uiFontBodyLarge(tokens: tokens)
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        if textField.text != cardholderName {
            textField.text = cardholderName
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            cardholderName: $cardholderName,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            scope: scope
        )
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        // MARK: - Properties

        @Binding private var cardholderName: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let validationService: ValidationService
        private let scope: any PrimerCardFormScope

        init(
            validationService: ValidationService,
            cardholderName: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            scope: any PrimerCardFormScope
        ) {
            self.validationService = validationService
            self._cardholderName = cardholderName
            self._isValid = isValid
            self._errorMessage = errorMessage
            self._isFocused = isFocused
            self.scope = scope
        }
        @objc func doneButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = true
                self.errorMessage = nil
                self.scope.clearFieldError(.cardholderName)
                // Don't set isValid = false immediately - let validation happen on text change or focus loss
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = false
            }
            validateCardholderName()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = cardholderName
            guard let textRange = Range(range, in: currentText) else { return false }
            let newText = currentText.replacingCharacters(in: textRange, with: string)
            // Validate allowed characters (letters, spaces, apostrophes, hyphens)
            if !string.isEmpty {
                let allowedCharacterSet = CharacterSet.letters.union(CharacterSet(charactersIn: " '-"))
                let characterSet = CharacterSet(charactersIn: string)
                if !allowedCharacterSet.isSuperset(of: characterSet) {
                    return false
                }
            }
            cardholderName = newText
            scope.updateCardholderName(newText)
            // Simple validation while typing
            isValid = newText.count >= 2
            // Update scope validation state while typing
            if let scope = scope as? DefaultCardFormScope {
                scope.updateCardholderNameValidationState(isValid)
            }
            return false
        }

        private func validateCardholderName() {
            let trimmedName = cardholderName.trimmingCharacters(in: .whitespacesAndNewlines)
            // Empty field handling - don't show errors for empty fields
            if trimmedName.isEmpty {
                isValid = false // Cardholder name is required
                errorMessage = nil
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCardholderNameValidationState(false)
                }
                return
            }
            let result = validationService.validate(
                input: cardholderName,
                with: CardholderNameRule()
            )
            isValid = result.isValid
            errorMessage = result.errorMessage
            // Update scope state based on validation
            if result.isValid {
                scope.clearFieldError(.cardholderName)
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCardholderNameValidationState(true)
                }
            } else {
                if let message = result.errorMessage {
                    scope.setFieldError(.cardholderName, message: message, errorCode: result.errorCode)
                }
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCardholderNameValidationState(false)
                }
            }
        }
    }
}
