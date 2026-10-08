//
//  CardholderNameInputField+UIViewRepresentable.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// UIViewRepresentable wrapper for cardholder name input
@available(iOS 15.0, *)
struct CardholderNameTextField: UIViewRepresentable, LogReporter {
  @Binding var cardholderName: String
  @Binding var isValid: Bool
  @Binding var errorMessage: String?
  @Binding var isFocused: Bool
  let placeholder: String
  let validationService: ValidationService
  let scope: any CardFormFieldScopeInternal
  let tokens: DesignTokens?

  func makeUIView(context: Context) -> UITextField {
    let textField = UITextField()
    textField.delegate = context.coordinator
    textField.accessibilityIdentifier = AccessibilityIdentifiers.inputField(within: AccessibilityIdentifiers.CardForm.cardholderNameField)

    textField.configurePrimerStyle(
      placeholder: placeholder,
      configuration: .standard,
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

  final class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
    private let validationService: ValidationService
    @Binding private var cardholderName: String
    @Binding private var isValid: Bool
    @Binding private var errorMessage: String?
    @Binding private var isFocused: Bool
    private let scope: any CardFormFieldScopeInternal

    init(
      validationService: ValidationService,
      cardholderName: Binding<String>,
      isValid: Binding<Bool>,
      errorMessage: Binding<String?>,
      isFocused: Binding<Bool>,
      scope: any CardFormFieldScopeInternal
    ) {
      self.validationService = validationService
      _cardholderName = cardholderName
      _isValid = isValid
      _errorMessage = errorMessage
      _isFocused = isFocused
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

    func textField(
      _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
      replacementString string: String
    ) -> Bool {
      let currentText = cardholderName

      guard let textRange = Range(range, in: currentText) else { return false }

      // Paste and AutoFill hand over a whole name, so drop what a name cannot hold instead of all of it.
      let accepted = Self.nameText(string)
      if !string.isEmpty, accepted.isEmpty {
        return false
      }
      let newText = currentText.replacingCharacters(in: textRange, with: accepted)

      cardholderName = newText
      scope.updateCardholderName(newText)

      isValid = newText.count >= 2

      scope.updateValidationState(\.cardholderName, isValid: isValid)

      return false
    }

    /// Contacts and paste bring typographic spaces, dashes and apostrophes, which would otherwise join or split a name.
    private static func nameText(_ string: String) -> String {
      let allowed = CharacterSet.letters.union(CharacterSet(charactersIn: " '-"))
      return string.map { character -> String in
        if character.isWhitespace { return " " }
        if character.unicodeScalars.first?.properties.generalCategory == .dashPunctuation { return "-" }
        if "\u{2018}\u{2019}".contains(character) { return "'" }
        // By its first scalar: an emoji's selector must not survive alone, and a letter's joiner must not drop it.
        guard let base = character.unicodeScalars.first, allowed.contains(base) else { return "" }
        return String(String.UnicodeScalarView(character.unicodeScalars.filter(allowed.contains)))
      }.joined()
    }

    private func validateCardholderName() {
      let trimmedName = cardholderName.trimmingCharacters(in: .whitespacesAndNewlines)

      // Empty field handling - don't show errors for empty fields
      if trimmedName.isEmpty {
        isValid = false  // Cardholder name is required
        errorMessage = nil  // Never show error message for empty fields
        scope.updateValidationState(\.cardholderName, isValid: false)
        return
      }

      let result = validationService.validate(
        input: cardholderName,
        with: CardholderNameRule()
      )

      isValid = result.isValid
      errorMessage = result.errorMessage

      if result.isValid {
        scope.clearFieldError(.cardholderName)
        scope.updateValidationState(\.cardholderName, isValid: true)
      } else {
        if let message = result.errorMessage {
          scope.setFieldError(.cardholderName, message: message, errorCode: result.errorCode)
        }
        scope.updateValidationState(\.cardholderName, isValid: false)
      }

    }
  }
}
