//
//  NameInputField+UIViewRepresentable.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// UIViewRepresentable wrapper for name input with focus-based validation
@available(iOS 15.0, *)
struct NameTextField: UIViewRepresentable {
    // MARK: - Properties

    @Binding var name: String
    @Binding var isValid: Bool
    @Binding var errorMessage: String?
    @Binding var isFocused: Bool
    
    let placeholder: String
    let inputType: PrimerInputElementType
    let styling: PrimerFieldStyling?
    let validationService: ValidationService
    let scope: (any PrimerCardFormScope)?
    let onNameChange: ((String) -> Void)?
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
        if textField.text != name {
            textField.text = name
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            name: $name,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            inputType: inputType,
            scope: scope,
            onNameChange: onNameChange,
            onValidationChange: onValidationChange
        )
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        // MARK: - Properties

        @Binding private var name: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let validationService: ValidationService
        private let inputType: PrimerInputElementType
        private let scope: (any PrimerCardFormScope)?
        private let onNameChange: ((String) -> Void)?
        private let onValidationChange: ((Bool) -> Void)?

        init(
            validationService: ValidationService,
            name: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            inputType: PrimerInputElementType,
            scope: (any PrimerCardFormScope)?,
            onNameChange: ((String) -> Void)?,
            onValidationChange: ((Bool) -> Void)?
        ) {
            self.validationService = validationService
            self._name = name
            self._isValid = isValid
            self._errorMessage = errorMessage
            self._isFocused = isFocused
            self.inputType = inputType
            self.scope = scope
            self.onNameChange = onNameChange
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
            validateName()
        }
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = name
            guard let textRange = Range(range, in: currentText) else { return false }
            let newText = currentText.replacingCharacters(in: textRange, with: string)
            name = newText
            if let scope {
                switch inputType {
                case .firstName:
                    scope.updateFirstName(newText)
                case .lastName:
                    scope.updateLastName(newText)
                case .phoneNumber:
                    scope.updatePhoneNumber(newText)
                default:
                    break
                }
            } else {
                onNameChange?(newText)
            }
            // Simple validation while typing (don't show errors until focus loss)
            isValid = !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            // Update scope validation state while typing
            if let scope = scope as? DefaultCardFormScope {
                switch inputType {
                case .firstName:
                    scope.updateFirstNameValidationState(isValid)
                case .lastName:
                    scope.updateLastNameValidationState(isValid)
                default:
                    break
                }
            }
            return false
        }
        private func validateName() {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            // Empty field handling - don't show errors for empty fields
            if trimmedName.isEmpty {
                isValid = false // Name fields are required
                errorMessage = nil
                onValidationChange?(false)
                // Update scope validation state for empty fields
                if let scope = scope as? DefaultCardFormScope {
                    switch inputType {
                    case .firstName:
                        scope.updateFirstNameValidationState(false)
                    case .lastName:
                        scope.updateLastNameValidationState(false)
                    default:
                        break
                    }
                }
                return
            }
            // Convert PrimerInputElementType to ValidationError.InputElementType
            let elementType: ValidationError.InputElementType = {
                switch inputType {
                case .firstName: .firstName
                case .lastName: .lastName
                default: .firstName
                }
            }()
            let result = validationService.validate(
                input: name,
                with: NameRule(inputElementType: elementType)
            )
            isValid = result.isValid
            errorMessage = result.errorMessage
            onValidationChange?(result.isValid)
            // Update scope state based on validation
            if let scope {
                if result.isValid {
                    scope.clearFieldError(inputType)
                        if let scope = scope as? DefaultCardFormScope {
                        switch inputType {
                        case .firstName:
                            scope.updateFirstNameValidationState(true)
                        case .lastName:
                            scope.updateLastNameValidationState(true)
                        default:
                            break
                        }
                    }
                } else if let message = result.errorMessage {
                    scope.setFieldError(inputType, message: message, errorCode: result.errorCode)
                        if let scope = scope as? DefaultCardFormScope {
                        switch inputType {
                        case .firstName:
                            scope.updateFirstNameValidationState(false)
                        case .lastName:
                            scope.updateLastNameValidationState(false)
                        default:
                            break
                        }
                    }
                }
            }
        }
    }
}
