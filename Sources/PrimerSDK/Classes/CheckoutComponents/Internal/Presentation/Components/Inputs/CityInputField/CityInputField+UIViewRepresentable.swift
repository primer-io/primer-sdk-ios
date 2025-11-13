//
//  CityInputField+UIViewRepresentable.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// UIViewRepresentable wrapper for city input with focus-based validation
@available(iOS 15.0, *)
struct CityTextField: UIViewRepresentable {
    // MARK: - Properties

    @Binding var city: String
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
        if textField.text != city {
            textField.text = city
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            city: $city,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            scope: scope
        )
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        // MARK: - Properties

        @Binding private var city: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let validationService: ValidationService
        private let scope: any PrimerCardFormScope

        init(
            validationService: ValidationService,
            city: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            scope: any PrimerCardFormScope
        ) {
            self.validationService = validationService
            self._city = city
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
                self.scope.clearFieldError(.city)
                // Don't set isValid = false immediately - let validation happen on text change or focus loss
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = false
            }
            validateCity()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = city
            city = currentText.replacingCharacters(in: range, with: string)
            scope.updateCity(city)
            isValid = !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            scope.updateValidationStateIfNeeded(for: .city, isValid: isValid)
            return false
        }

        private func validateCity() {
            let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedCity.isEmpty {
                isValid = false
                errorMessage = nil
                scope.updateValidationStateIfNeeded(for: .city, isValid: false)
                return
            }
            let result = validationService.validate(
                input: city,
                with: CityRule()
            )
            isValid = result.isValid
            errorMessage = result.errorMessage
            if result.isValid {
                scope.clearFieldError(.city)
                scope.updateValidationStateIfNeeded(for: .city, isValid: true)
            } else if let message = result.errorMessage {
                scope.setFieldError(.city, message: message, errorCode: result.errorCode)
                scope.updateValidationStateIfNeeded(for: .city, isValid: false)
            }
        }
    }
}
