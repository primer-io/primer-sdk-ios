//
//  ExpiryDateInputField+UIViewRepresentable.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

/// UIViewRepresentable wrapper for expiry date input
@available(iOS 15.0, *)
struct ExpiryDateTextField: UIViewRepresentable, LogReporter {
  @Binding var expiryDate: String
  @Binding var month: String
  @Binding var year: String
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
      configuration: .expiryDate,
      styling: styling,
      tokens: tokens,
      doneButtonTarget: context.coordinator,
      doneButtonAction: #selector(Coordinator.doneButtonTapped)
    )

    return textField
  }

  func updateUIView(_ textField: UITextField, context: Context) {
    if textField.text != expiryDate {
      textField.text = expiryDate
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(
      validationService: validationService,
      expiryDate: $expiryDate,
      month: $month,
      year: $year,
      isValid: $isValid,
      errorMessage: $errorMessage,
      isFocused: $isFocused,
      scope: scope
    )
  }

  class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
    private let validationService: ValidationService
    @Binding private var expiryDate: String
    @Binding private var month: String
    @Binding private var year: String
    @Binding private var isValid: Bool
    @Binding private var errorMessage: String?
    @Binding private var isFocused: Bool
    private let scope: any PrimerCardFormScope

    init(
      validationService: ValidationService,
      expiryDate: Binding<String>,
      month: Binding<String>,
      year: Binding<String>,
      isValid: Binding<Bool>,
      errorMessage: Binding<String?>,
      isFocused: Binding<Bool>,
      scope: any PrimerCardFormScope
    ) {
      self.validationService = validationService
      self._expiryDate = expiryDate
      self._month = month
      self._year = year
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
        self.scope.clearFieldError(.expiryDate)
      }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
      DispatchQueue.main.async {
        self.isFocused = false
      }
      validateExpiryDate()
    }

    func textField(
      _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
      replacementString string: String
    ) -> Bool {
      let currentText = expiryDate

      if string == "\n" {
        textField.resignFirstResponder()
        return false
      }

      // Only allow numbers and return for non-numeric input except deletion
      if !string.isEmpty,
        !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string))
      {
        return false
      }

      let newText = processInput(currentText: currentText, range: range, string: string)

      expiryDate = newText
      textField.text = newText

      extractMonthAndYear(from: newText)

      scope.updateExpiryDate(newText)

      // Validate silently during typing (no error messages shown)
      if newText.count == 5 {  // MM/YY format
        validateExpiryDateSilently()
      } else {
        isValid = false
        errorMessage = nil
      }

      return false
    }

    private func processInput(currentText: String, range: NSRange, string: String) -> String {
      if string.isEmpty {
        // If deleting the separator, also remove the character before it
        if range.location == 2, range.length == 1, currentText.count >= 3,
          currentText[currentText.index(currentText.startIndex, offsetBy: 2)] == "/"
        {
          return String(currentText.prefix(1))
        }

        if let textRange = Range(range, in: currentText) {
          return currentText.replacingCharacters(in: textRange, with: "")
        }
        return currentText
      }

      // Remove the / character temporarily for easier processing
      let sanitizedText = currentText.replacingOccurrences(of: "/", with: "")

      // Calculate where to insert the new text
      var sanitizedLocation = range.location
      if range.location > 2, currentText.count >= 3, currentText.contains("/") {
        sanitizedLocation -= 1
      }

      var newSanitizedText = sanitizedText
      if sanitizedLocation <= sanitizedText.count {
        let index = newSanitizedText.index(
          newSanitizedText.startIndex, offsetBy: min(sanitizedLocation, newSanitizedText.count))
        newSanitizedText.insert(contentsOf: string, at: index)
      } else {
        newSanitizedText += string
      }

      // Limit to 4 digits total (MMYY format)
      newSanitizedText = String(newSanitizedText.prefix(4))

      if newSanitizedText.count > 2 {
        return "\(newSanitizedText.prefix(2))/\(newSanitizedText.dropFirst(2))"
      } else {
        return newSanitizedText
      }
    }

    private func extractMonthAndYear(from text: String) {
      let parts = text.components(separatedBy: "/")

      month = parts.count > 0 ? parts[0] : ""
      year = parts.count > 1 ? parts[1] : ""

      scope.updateExpiryMonth(month)
      scope.updateExpiryYear(year)
    }

    /// Validates expiry date and shows error messages (called on blur)
    private func validateExpiryDate() {
      validateExpiryDateSilently(showErrors: true)
    }

    /// Validates expiry date without showing error messages (called during typing)
    private func validateExpiryDateSilently(showErrors: Bool = false) {
      // Empty field handling - don't show errors for empty fields
      let trimmedExpiry = expiryDate.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmedExpiry.isEmpty {
        isValid = false  // Expiry date is required
        errorMessage = nil  // Never show error message for empty fields
        if let scope = scope as? DefaultCardFormScope {
          scope.updateExpiryValidationState(false)
        }
        return
      }

      // Parse MM/YY format for non-empty fields
      let components = expiryDate.components(separatedBy: "/")

      guard components.count == 2 else {
        isValid = false
        if showErrors {
          errorMessage = CheckoutComponentsStrings.enterValidExpiryDate
          scope.setFieldError(
            .expiryDate, message: CheckoutComponentsStrings.enterValidExpiryDate,
            errorCode: "invalid_format")
        }
        if let scope = scope as? DefaultCardFormScope {
          scope.updateExpiryValidationState(false)
        }
        return
      }

      let month = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
      let year = components[1].trimmingCharacters(in: .whitespacesAndNewlines)

      let expiryInput = ExpiryDateInput(month: month, year: year)
      let result = validationService.validate(
        input: expiryInput,
        with: ExpiryDateRule()
      )

      isValid = result.isValid

      // Only show error messages if showErrors is true (on blur)
      if showErrors {
        errorMessage = result.errorMessage
      }

      if result.isValid {
        scope.clearFieldError(.expiryDate)
        if let scope = scope as? DefaultCardFormScope {
          scope.updateExpiryValidationState(true)
        }
      } else {
        if showErrors, let message = result.errorMessage {
          scope.setFieldError(.expiryDate, message: message, errorCode: result.errorCode)
        }
        if let scope = scope as? DefaultCardFormScope {
          scope.updateExpiryValidationState(false)
        }
      }
    }
  }
}
