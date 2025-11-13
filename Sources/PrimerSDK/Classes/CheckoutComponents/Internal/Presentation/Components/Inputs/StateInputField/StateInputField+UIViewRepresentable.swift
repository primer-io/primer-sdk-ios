//
//  StateInputField+UIViewRepresentable.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// UIViewRepresentable wrapper for state input with focus-based validation
@available(iOS 15.0, *)
struct StateTextField: UIViewRepresentable {
    // MARK: - Properties

    @Binding var state: String
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
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        if textField.text != state {
            textField.text = state
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            state: $state,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            scope: scope
        )
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        // MARK: - Properties

        @Binding private var state: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let validationService: ValidationService
        private let scope: any PrimerCardFormScope

        init(
            validationService: ValidationService,
            state: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            scope: any PrimerCardFormScope
        ) {
            self.validationService = validationService
            self._state = state
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
                self.scope.clearFieldError(.state)
                // Don't set isValid = false immediately - let validation happen on text change or focus loss
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = false
            }
            validateState()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = state
            state = currentText.replacingCharacters(in: range, with: string)
            scope.updateState(state)
            isValid = !state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            scope.updateValidationStateIfNeeded(for: .state, isValid: isValid)
            return false
        }

        private func validateState() {
            let trimmedState = state.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedState.isEmpty {
                isValid = false
                errorMessage = nil
                scope.updateValidationStateIfNeeded(for: .state, isValid: false)
                return
            }
            let result = validationService.validate(
                input: state,
                with: StateRule()
            )
            isValid = result.isValid
            errorMessage = result.errorMessage
            if result.isValid {
                scope.clearFieldError(.state)
                scope.updateValidationStateIfNeeded(for: .state, isValid: true)
            } else if let message = result.errorMessage {
                scope.setFieldError(.state, message: message, errorCode: result.errorCode)
                scope.updateValidationStateIfNeeded(for: .state, isValid: false)
            }
        }
    }
}
