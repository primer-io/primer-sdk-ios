//
//  StateInputField+UIViewRepresentable.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

/// UIViewRepresentable wrapper for state input with focus-based validation
@available(iOS 15.0, *)
struct StateTextField: UIViewRepresentable, LogReporter {
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

  class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
    private let validationService: ValidationService
    @Binding private var state: String
    @Binding private var isValid: Bool
    @Binding private var errorMessage: String?
    @Binding private var isFocused: Bool
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
      UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
      // Post accessibility notification to move focus away from the now-hidden Done button
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
      }
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

    func textField(
      _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
      replacementString string: String
    ) -> Bool {
      let currentText = state

      guard let textRange = Range(range, in: currentText) else { return false }
      let newText = currentText.replacingCharacters(in: textRange, with: string)

      state = newText
      scope.updateState(newText)

      // Simple validation while typing (don't show errors until focus loss)
      isValid = !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

      if let scope = scope as? DefaultCardFormScope {
        scope.updateStateValidationState(isValid)
      }

      return false
    }

    private func validateState() {
      let trimmedState = state.trimmingCharacters(in: .whitespacesAndNewlines)

      // Empty field handling - don't show errors for empty fields
      if trimmedState.isEmpty {
        isValid = false  // State is required
        errorMessage = nil  // Never show error message for empty fields
        if let scope = scope as? DefaultCardFormScope {
          scope.updateStateValidationState(false)
        }
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
        if let scope = scope as? DefaultCardFormScope {
          scope.updateStateValidationState(true)
        }
      } else if let message = result.errorMessage {
        scope.setFieldError(.state, message: message, errorCode: result.errorCode)
        if let scope = scope as? DefaultCardFormScope {
          scope.updateStateValidationState(false)
        }
      }
    }
  }
}
