//
//  AddressLineInputField+UIViewRepresentable.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// UIViewRepresentable wrapper for address line input with focus-based validation
@available(iOS 15.0, *)
struct AddressLineTextField: UIViewRepresentable {
    // MARK: - Properties

    @Binding var addressLine: String
    @Binding var isValid: Bool
    @Binding var errorMessage: String?
    @Binding var isFocused: Bool
    
    let placeholder: String
    let isRequired: Bool
    let inputType: PrimerInputElementType
    let styling: PrimerFieldStyling?
    let validationService: ValidationService
    let scope: (any PrimerCardFormScope)?
    let onAddressChange: ((String) -> Void)?
    let onValidationChange: ((Bool) -> Void)?
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
        if textField.text != addressLine {
            textField.text = addressLine
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            addressLine: $addressLine,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            isRequired: isRequired,
            inputType: inputType,
            scope: scope,
            onAddressChange: onAddressChange,
            onValidationChange: onValidationChange
        )
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        // MARK: - Properties

        @Binding private var addressLine: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let validationService: ValidationService
        private let isRequired: Bool
        private let inputType: PrimerInputElementType
        private let scope: (any PrimerCardFormScope)?
        private let onAddressChange: ((String) -> Void)?
        private let onValidationChange: ((Bool) -> Void)?

        init(
            validationService: ValidationService,
            addressLine: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            isRequired: Bool,
            inputType: PrimerInputElementType,
            scope: (any PrimerCardFormScope)?,
            onAddressChange: ((String) -> Void)?,
            onValidationChange: ((Bool) -> Void)?
        ) {
            self.validationService = validationService
            self._addressLine = addressLine
            self._isValid = isValid
            self._errorMessage = errorMessage
            self._isFocused = isFocused
            self.isRequired = isRequired
            self.inputType = inputType
            self.scope = scope
            self.onAddressChange = onAddressChange
            self.onValidationChange = onValidationChange
        }

        @objc func doneButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = true
                self.errorMessage = nil
                self.scope?.clearFieldError(self.inputType)
                // Don't set isValid = false immediately - let validation happen on text change or focus loss
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = false
            }
            validateAddress()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = addressLine
            guard let textRange = Range(range, in: currentText) else { return false }
            addressLine = currentText.replacingCharacters(in: textRange, with: string)
            if let scope {
                switch inputType {
                case .addressLine1:
                    scope.updateAddressLine1(addressLine)
                case .addressLine2:
                    scope.updateAddressLine2(addressLine)
                default:
                    break
                }
            } else {
                onAddressChange?(addressLine)
            }
            if isRequired {
                isValid = !addressLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            } else {
                isValid = true
            }
            scope?.updateValidationStateIfNeeded(for: inputType, isValid: isValid)
            return false
        }

        private func validateAddress() {
            let trimmedAddress = addressLine.trimmingCharacters(in: .whitespacesAndNewlines)
            // Empty field handling - don't show errors for empty fields
            if trimmedAddress.isEmpty {
                isValid = isRequired ? false : true
                errorMessage = nil
                onValidationChange?(isValid)
                scope?.clearFieldError(inputType)
                scope?.updateValidationStateIfNeeded(for: inputType, isValid: isValid)
                return
            }
            // Convert PrimerInputElementType to ValidationError.InputElementType
            let elementType: ValidationError.InputElementType = {
                switch inputType {
                case .addressLine1: .addressLine1
                case .addressLine2: .addressLine2
                default: .addressLine1
                }
            }()
            let result = validationService.validate(
                input: addressLine,
                with: AddressRule(inputElementType: elementType, isRequired: isRequired)
            )
            isValid = result.isValid
            errorMessage = result.errorMessage
            onValidationChange?(result.isValid)
            if let scope {
                if result.isValid {
                    scope.clearFieldError(inputType)
                    scope.updateValidationStateIfNeeded(for: inputType, isValid: true)
                } else if let message = result.errorMessage {
                    scope.setFieldError(inputType, message: message, errorCode: result.errorCode)
                    scope.updateValidationStateIfNeeded(for: inputType, isValid: false)
                }
            }
        }
    }
}
