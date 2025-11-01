//
//  CVVInputField+UIViewRepresentable.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

/// UIViewRepresentable wrapper for CVV text field
@available(iOS 15.0, *)
struct CVVTextField: UIViewRepresentable, LogReporter {
    @Binding var cvv: String
    @Binding var isValid: Bool
    @Binding var errorMessage: String?
    @Binding var isFocused: Bool
    let placeholder: String
    let cardNetwork: CardNetwork
    let styling: PrimerFieldStyling?
    let validationService: ValidationService
    let scope: any PrimerCardFormScope
    let tokens: DesignTokens?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator

        textField.configurePrimerStyle(
            placeholder: placeholder,
            configuration: .cvv,
            styling: styling,
            tokens: tokens,
            doneButtonTarget: context.coordinator,
            doneButtonAction: #selector(Coordinator.doneButtonTapped)
        )

        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        if textField.text != cvv {
            textField.text = cvv
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            cardNetwork: cardNetwork,
            cvv: $cvv,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            scope: scope
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        private let validationService: ValidationService
        private let cardNetwork: CardNetwork
        @Binding private var cvv: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let scope: any PrimerCardFormScope

        private var expectedCVVLength: Int {
            cardNetwork.validation?.code.length ?? 3
        }

        init(
            validationService: ValidationService,
            cardNetwork: CardNetwork,
            cvv: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            scope: any PrimerCardFormScope
        ) {
            self.validationService = validationService
            self.cardNetwork = cardNetwork
            self._cvv = cvv
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
                self.scope.clearFieldError(.cvv)
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = false
            }
            validateCVV()
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Get current text
            let currentText = cvv

            // Create the new text
            guard let textRange = Range(range, in: currentText) else { return false }
            let newText = currentText.replacingCharacters(in: textRange, with: string)

            // Only allow numbers
            if !string.isEmpty && !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)) {
                return false
            }

            // Check max length
            if newText.count > expectedCVVLength {
                return false
            }

            // Update state
            cvv = newText
            scope.updateCvv(newText)

            // Validate while typing
            if newText.count == expectedCVVLength {
                validateCVV()
            } else {
                isValid = false
                errorMessage = nil
                // Update scope validation state for incomplete CVV
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCvvValidationState(false)
                }
            }

            return false
        }

        private func validateCVV() {
            // Empty field handling - don't show errors for empty fields
            let trimmedCVV = cvv.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedCVV.isEmpty {
                isValid = false // CVV is required
                errorMessage = nil // Never show error message for empty fields
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCvvValidationState(false)
                }
                return
            }

            // Create CVVRule with the current card network for non-empty fields
            let cvvRule = CVVRule(cardNetwork: cardNetwork)
            let result = cvvRule.validate(cvv)

            isValid = result.isValid
            errorMessage = result.errorMessage

            // Update scope state based on validation
            if result.isValid {
                scope.clearFieldError(.cvv)
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCvvValidationState(true)
                }
            } else {
                if let message = result.errorMessage {
                    scope.setFieldError(.cvv, message: message, errorCode: result.errorCode)
                }
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCvvValidationState(false)
                }
            }
        }
    }
}
