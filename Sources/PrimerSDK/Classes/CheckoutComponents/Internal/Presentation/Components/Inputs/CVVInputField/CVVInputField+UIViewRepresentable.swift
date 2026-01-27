//
//  CVVInputField+UIViewRepresentable.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
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
        self.scope.clearFieldError(.cvv)
      }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
      DispatchQueue.main.async {
        self.isFocused = false
      }
      validateCVV()
    }

    func textField(
      _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
      replacementString string: String
    ) -> Bool {
      let currentText = cvv

      guard let textRange = Range(range, in: currentText) else { return false }
      let newText = currentText.replacingCharacters(in: textRange, with: string)

      // Only allow numbers
      if !string.isEmpty,
        !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string))
      {
        return false
      }

      if newText.count > expectedCVVLength {
        return false
      }

      cvv = newText
      scope.updateCvv(newText)

      if newText.count == expectedCVVLength {
        validateCVV()
      } else {
        isValid = false
        errorMessage = nil
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
        isValid = false  // CVV is required
        errorMessage = nil  // Never show error message for empty fields
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

      if result.isValid {
        scope.clearFieldError(.cvv)
        if let scope = scope as? DefaultCardFormScope {
          scope.updateCvvValidationState(true)
        }
      } else {
        if let message = result.errorMessage {
          scope.setFieldError(.cvv, message: message, errorCode: result.errorCode)
        }
        if let scope = scope as? DefaultCardFormScope {
          scope.updateCvvValidationState(false)
        }
      }
    }
  }
}
