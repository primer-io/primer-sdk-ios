//
//  CVVInputField+UIViewRepresentable.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// UIViewRepresentable wrapper for CVV text field
@available(iOS 15.0, *)
struct CVVTextField: UIViewRepresentable {
    // MARK: - Properties

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

    final class Coordinator: NSObject, UITextFieldDelegate {
        // MARK: - Properties

        @Binding private var cvv: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let validationService: ValidationService
        private let cardNetwork: CardNetwork
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
            let currentText = cvv
            if !string.isEmpty && !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)) {
                return false
            }
            let replacementLength = range.length
            let resultingLength = currentText.count - replacementLength + string.count
            if resultingLength > expectedCVVLength {
                return false
            }
            cvv = currentText.replacingCharacters(in: range, with: string)
            scope.updateCvv(cvv)
            if cvv.count == expectedCVVLength {
                validateCVV()
            } else {
                isValid = false
                errorMessage = nil
                scope.updateValidationStateIfNeeded(for: .cvv, isValid: false)
            }
            return false
        }

        private func validateCVV() {
            let trimmedCVV = cvv.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedCVV.isEmpty {
                isValid = false
                errorMessage = nil
                scope.updateValidationStateIfNeeded(for: .cvv, isValid: false)
                return
            }
            let cvvRule = CVVRule(cardNetwork: cardNetwork)
            let result = cvvRule.validate(cvv)
            isValid = result.isValid
            errorMessage = result.errorMessage
            if result.isValid {
                scope.clearFieldError(.cvv)
                scope.updateValidationStateIfNeeded(for: .cvv, isValid: true)
            } else {
                if let message = result.errorMessage {
                    scope.setFieldError(.cvv, message: message, errorCode: result.errorCode)
                }
                scope.updateValidationStateIfNeeded(for: .cvv, isValid: false)
            }
        }
    }
}
