//
//  BaseTextFieldCoordinator.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

import UIKit

/// Base coordinator that composes formatting, cursor, and validation
public class BaseTextFieldCoordinator: NSObject, UITextFieldDelegate {
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

        // Then filter and format
        let newRaw = updatedText.filter { $0.isNumber || $0.isLetter }
        let formatted = formatter.format(newRaw)

        textField.text = formatted
        onTextChange(formatted)

        // Calculate cursor position
        let cursorPosition = range.location + string.count
        let cursorPos = cursorManager.position(for: newRaw, formatted: formatted, original: cursorPosition)

        if let pos = textField.position(from: textField.beginningOfDocument, offset: min(cursorPos, formatted.count)) {
            textField.selectedTextRange = textField.textRange(from: pos, to: pos)
        }

        lastRaw = newRaw
        let result = validator.validateWhileTyping(newRaw)
        onValidationChange(result.isValid)
        onErrorMessageChange(result.errorMessage)

        return false
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        let result = validator.validateOnCommit(lastRaw)
        onValidationChange(result.isValid)
        onErrorMessageChange(result.errorMessage)
    }
}
