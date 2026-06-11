//
//  CardNumberInputField+UIViewRepresentable.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
struct CardNumberTextField: UIViewRepresentable, LogReporter {
  @Binding var cardNumber: String
  @Binding var isValid: Bool
  @Binding var cardNetwork: CardNetwork
  @Binding var errorMessage: String?
  @Binding var isFocused: Bool

  let scope: any CardFormFieldScopeInternal
  let placeholder: String
  let validationService: ValidationService
  let tokens: DesignTokens?

  func makeUIView(context: Context) -> SecureTextField {
    let textField = SecureTextField()
    textField.delegate = context.coordinator

    textField.configurePrimerStyle(
      placeholder: placeholder,
      configuration: .numberPad,
      tokens: tokens,
      doneButtonTarget: context.coordinator,
      doneButtonAction: #selector(Coordinator.doneButtonTapped)
    )

    return textField
  }

  func updateUIView(_ textField: SecureTextField, context: Context) {
    let formatted = CardNumberFormatter.format(cardNumber, for: cardNetwork)
    if textField.internalText != formatted {
      textField.internalText = formatted
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(
      scope: scope,
      validationService: validationService,
      cardNumber: $cardNumber,
      cardNetwork: $cardNetwork,
      isValid: $isValid,
      errorMessage: $errorMessage,
      isFocused: $isFocused
    )
  }

  final class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
    // MARK: - Properties

    @Binding private var cardNumber: String
    @Binding private var cardNetwork: CardNetwork
    @Binding private var isValid: Bool
    @Binding private var errorMessage: String?
    @Binding private var isFocused: Bool
    private let scope: any CardFormFieldScopeInternal
    private let validationService: ValidationService
    private var savedCursorPosition: Int = 0
    private var validationTimer: Timer?

    init(
      scope: any CardFormFieldScopeInternal,
      validationService: ValidationService,
      cardNumber: Binding<String>,
      cardNetwork: Binding<CardNetwork>,
      isValid: Binding<Bool>,
      errorMessage: Binding<String?>,
      isFocused: Binding<Bool>
    ) {
      self.scope = scope
      self.validationService = validationService
      _cardNumber = cardNumber
      _cardNetwork = cardNetwork
      _isValid = isValid
      _errorMessage = errorMessage
      _isFocused = isFocused
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
        self.scope.clearFieldError(.cardNumber)
      }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
      DispatchQueue.main.async {
        self.isFocused = false
        self.validateCardNumberFully(self.cardNumber)
      }
    }

    func textField(
      _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
      replacementString string: String
    ) -> Bool {
      let secureTextField = textField as? SecureTextField
      saveCursorPosition(textField)
      let currentText = cardNumber
      let isDeletion = string.isEmpty
      let newCardNumber = processTextFieldChange(
        currentText: currentText,
        range: range,
        replacementString: string,
        formattedText: secureTextField?.internalText ?? "",
        isDeletion: isDeletion
      )
      guard newCardNumber != currentText || isDeletion else {
        return false
      }
      cardNumber = newCardNumber
      scope.updateCardNumber(newCardNumber)
      updateCardNetworkIfNeeded(newCardNumber)
      let formattedText = CardNumberFormatter.format(newCardNumber, for: cardNetwork)
      secureTextField?.internalText = formattedText
      restoreCursorPosition(
        textField: textField,
        formattedText: formattedText,
        originalCursorPos: savedCursorPosition,
        isDeletion: isDeletion,
        insertedLength: isDeletion ? 0 : string.count
      )
      updateValidationState(newCardNumber)
      return false
    }

    private func processTextFieldChange(
      currentText: String,
      range: NSRange,
      replacementString string: String,
      formattedText: String,
      isDeletion: Bool
    ) -> String {
      var newCardNumber: String
      if isDeletion {
        newCardNumber = processDeletion(
          currentText: currentText,
          range: range,
          formattedText: formattedText
        )
      } else {
        let filteredText = string.filter(\.isNumber)
        if filteredText.isEmpty {
          return currentText
        }
        newCardNumber = processInsertion(
          currentText: currentText,
          range: range,
          formattedText: formattedText,
          insertText: filteredText
        )
      }
      if newCardNumber.count > 19 {
        newCardNumber = String(newCardNumber.prefix(19))
      }
      return newCardNumber
    }

    private func processDeletion(
      currentText: String,
      range: NSRange,
      formattedText: String
    ) -> String {
      if range.length > 0 {
        let unformattedRange = getUnformattedRange(
          formattedRange: range,
          formattedText: formattedText,
          unformattedText: currentText
        )
        return handleDeletion(currentText: currentText, unformattedRange: unformattedRange)
      } else if range.location > 0 {
        let unformattedPos = calculateUnformattedPosition(
          upToIndex: range.location,
          in: formattedText
        )
        if unformattedPos > 0, unformattedPos <= currentText.count {
          let index = currentText.index(currentText.startIndex, offsetBy: unformattedPos - 1)
          return currentText.removing(at: index)
        }
      }
      return currentText
    }

    private func processInsertion(
      currentText: String,
      range: NSRange,
      formattedText: String,
      insertText: String
    ) -> String {
      let unformattedPos = calculateUnformattedPosition(
        upToIndex: range.location,
        in: formattedText
      )
      if unformattedPos <= currentText.count {
        let index = currentText.index(currentText.startIndex, offsetBy: unformattedPos)
        return currentText.inserting(contentsOf: insertText, at: index)
      } else {
        return currentText + insertText
      }
    }

    private func calculateUnformattedPosition(upToIndex index: Int, in formattedText: String) -> Int {
      formattedText.enumerated().reduce(into: 0) { count, element in
        if element.offset < index, element.element.isNumber {
          count += 1
        }
      }
    }

    private func updateCardNetworkIfNeeded(_ newCardNumber: String) {
      let newNetwork = CardNetwork(cardNumber: newCardNumber)
      if newNetwork != cardNetwork {
        // Keep the local binding updated for formatting, but let the scope decide whether to apply
        // it: a user-pinned co-badge network must not be overwritten by auto-detection.
        cardNetwork = newNetwork
        scope.autoSelectDetectedNetwork(newNetwork.rawValue)
      }
    }

    private func updateValidationState(_ newCardNumber: String) {
      if newCardNumber.count >= 13 {
        debouncedValidation(newCardNumber)
      } else if newCardNumber.isEmpty {
        isValid = false
        errorMessage = nil
        scope.clearFieldError(.cardNumber)
        scope.updateValidationStateIfNeeded(for: .cardNumber, isValid: false)
      }
    }

    private func saveCursorPosition(_ textField: UITextField) {
      if let selectedRange = textField.selectedTextRange {
        savedCursorPosition = textField.offset(
          from: textField.beginningOfDocument, to: selectedRange.start)
      }
    }

    private func restoreCursorPosition(
      textField: UITextField, formattedText: String, originalCursorPos: Int, isDeletion: Bool,
      insertedLength: Int
    ) {
      var newCursorPosition: Int
      if isDeletion {
        newCursorPosition = min(originalCursorPos, formattedText.count)
      } else {
        newCursorPosition = min(originalCursorPos + insertedLength, formattedText.count)
        if originalCursorPos < formattedText.count {
          let spacesAdded = formattedText.prefix(newCursorPosition).filter { $0 == " " }.count
          newCursorPosition = min(
            originalCursorPos + insertedLength + spacesAdded, formattedText.count)
        }
      }
      DispatchQueue.main.async {
        if let newPosition = textField.position(
          from: textField.beginningOfDocument, offset: newCursorPosition) {
          textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
        }
      }
    }

    private func getUnformattedRange(
      formattedRange: NSRange, formattedText: String, unformattedText: String
    ) -> NSRange {
      let rangeEnd = formattedRange.location + formattedRange.length
      var unformattedLocation = 0
      var unformattedLength = 0
      for (index, char) in formattedText.enumerated() where char.isNumber {
        if index < formattedRange.location {
          unformattedLocation += 1
        } else if index < rangeEnd {
          unformattedLength += 1
        }
      }
      return NSRange(location: unformattedLocation, length: unformattedLength)
    }

    private func handleDeletion(currentText: String, unformattedRange: NSRange) -> String {
      if unformattedRange.length > 0 {
        if unformattedRange.location >= currentText.count {
          return currentText
        }
        let startIndex = currentText.index(
          currentText.startIndex, offsetBy: unformattedRange.location)
        let endIndex = currentText.index(
          startIndex,
          offsetBy: min(unformattedRange.length, currentText.count - unformattedRange.location))
        return currentText.replacingCharacters(in: startIndex..<endIndex, with: "")
      }
      if unformattedRange.location >= currentText.count, !currentText.isEmpty {
        return String(currentText.dropLast())
      }
      if unformattedRange.location > 0, unformattedRange.location <= currentText.count {
        let index = currentText.index(
          currentText.startIndex, offsetBy: unformattedRange.location - 1)
        return currentText.removing(at: index)
      }
      return currentText
    }

    private func debouncedValidation(_ number: String) {
      validationTimer?.invalidate()
      validationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) {
        [weak self] _ in
        guard let self else { return }
        validateCardNumberWhileTyping(number)
      }
    }

    private func validateCardNumberWhileTyping(_ number: String) {
      if number.count < 13 {
        isValid = false
        errorMessage = nil
        scope.updateValidationStateIfNeeded(for: .cardNumber, isValid: false)
        return
      }

      let network = CardNetwork(cardNumber: number)
      if network != .unknown, let validation = network.validation,
        validation.lengths.contains(number.count) {
        let validationResult = validationService.validateCardNumber(number)
        if validationResult.isValid {
          isValid = true
          errorMessage = nil
          scope.updateValidationStateIfNeeded(for: .cardNumber, isValid: true)
        } else {
          isValid = false
          errorMessage = nil
          scope.updateValidationStateIfNeeded(for: .cardNumber, isValid: false)
        }
      } else if number.count >= 16 {
        let validationResult = validationService.validateCardNumber(number)
        if validationResult.isValid {
          isValid = true
          errorMessage = nil
          scope.updateValidationStateIfNeeded(for: .cardNumber, isValid: true)
        } else {
          isValid = false
          errorMessage = nil
          scope.updateValidationStateIfNeeded(for: .cardNumber, isValid: false)
        }
      } else {
        isValid = false
        errorMessage = nil
        scope.updateValidationStateIfNeeded(for: .cardNumber, isValid: false)
      }
    }

    private func validateCardNumberFully(_ number: String) {
      validationTimer?.invalidate()
      let trimmedNumber = number.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmedNumber.isEmpty {
        isValid = false
        errorMessage = nil
        scope.updateValidationStateIfNeeded(for: .cardNumber, isValid: false)
        return
      }

      let validationResult = validationService.validateCardNumber(number)
      isValid = validationResult.isValid
      if validationResult.isValid {
        errorMessage = nil
        scope.clearFieldError(.cardNumber)
        scope.updateValidationStateIfNeeded(for: .cardNumber, isValid: true)
      } else {
        errorMessage = validationResult.errorMessage
        if let errorMessage = validationResult.errorMessage {
          scope.setFieldError(
            .cardNumber, message: errorMessage, errorCode: validationResult.errorCode)
        }
        scope.updateValidationStateIfNeeded(for: .cardNumber, isValid: false)
      }
    }
    deinit {
      validationTimer?.invalidate()
    }
  }
}

enum CardNumberFormatter {
  static func format(_ number: String, for network: CardNetwork) -> String {
    let gaps = network.validation?.gaps ?? [4, 8, 12]
    var formatted = ""
    for (index, char) in number.enumerated() {
      formatted.append(char)
      if gaps.contains(index + 1), index + 1 < number.count {
        formatted.append(" ")
      }
    }
    return formatted
  }
}

extension String {
  fileprivate func removing(at index: Index) -> String {
    var result = self
    result.remove(at: index)
    return result
  }
  fileprivate func inserting(contentsOf newElements: String, at index: Index) -> String {
    var result = self
    result.insert(contentsOf: newElements, at: index)
    return result
  }
}
