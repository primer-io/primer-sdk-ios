//
//  BaseTextFieldCoordinator.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

import UIKit

/// Base coordinator that composes formatting, cursor, and validation
public class BaseTextFieldCoordinator: NSObject, UITextFieldDelegate, LogReporter {
    let formatter: FieldFormatter
    let cursorManager: CursorPositionManaging
    let validator: FieldValidator
    let onValidationChange: (Bool) -> Void
    let onErrorMessageChange: (String?) -> Void
    let onTextChange: (String) -> Void

    private var lastRaw: String = ""

    public init(
        formatter: FieldFormatter,
        cursorManager: CursorPositionManaging,
        validator: FieldValidator,
        onValidationChange: @escaping (Bool) -> Void,
        onErrorMessageChange: @escaping (String?) -> Void,
        onTextChange: @escaping (String) -> Void
    ) {
        self.formatter = formatter
        self.cursorManager = cursorManager
        self.validator = validator
        self.onValidationChange = onValidationChange
        self.onErrorMessageChange = onErrorMessageChange
        self.onTextChange = onTextChange
    }

    public func textField(_ textField: UITextField,
                          shouldChangeCharactersIn range: NSRange,
                          replacementString string: String) -> Bool {
        guard let current = (textField.text ?? "") as String? else { return true }

        // Convert to Swift range and apply edit to original text first
        guard let swiftRange = Range(range, in: current) else { return false }
        let updatedText = current.replacingCharacters(in: swiftRange, with: string)

        // More flexible filtering - preserve formatting characters like / for dates
        // This allows expiry dates to maintain their format (MM/YY)
        let newRaw = if formatter is ExpiryDateFormatter {
            updatedText.filter { $0.isNumber || $0 == "/" }
        } else if formatter is CVVFormatter {
            updatedText.filter { $0.isNumber }
        } else if formatter is CardholderNameFormatter {
            updatedText.filter { $0.isLetter || $0.isWhitespace || $0 == "'" || $0 == "-" }
        } else {
            updatedText.filter { $0.isNumber || $0.isLetter }
        }

        // Format the text according to field type
        let formatted = formatter.format(newRaw)
        textField.text = formatted
        onTextChange(formatted)

        // Calculate cursor position
        let cursorPosition = range.location + string.count
        let cursorPos = cursorManager.position(for: newRaw, formatted: formatted, original: cursorPosition)
        if let pos = textField.position(from: textField.beginningOfDocument, offset: min(cursorPos, formatted.count)) {
            textField.selectedTextRange = textField.textRange(from: pos, to: pos)
        }

        // Store the raw value for later validation on blur
        lastRaw = newRaw

        // Perform validation and update state/UI
        let result = validator.validateWhileTyping(newRaw)
        logger.debug(message: "DEBUG: While typing validation: '\(newRaw)' - valid: \(result.isValid), error: \(result.errorMessage ?? "none")")

        // Update validation state in parent component
        onValidationChange(result.isValid)

        // Always update error message - this will clear it when validation passes
        onErrorMessageChange(result.errorMessage)

        return false
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        // Clear error message when user starts editing
        onErrorMessageChange(nil)
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        let result = validator.validateOnCommit(lastRaw)
        onValidationChange(result.isValid)
        onErrorMessageChange(result.errorMessage)
    }
}
