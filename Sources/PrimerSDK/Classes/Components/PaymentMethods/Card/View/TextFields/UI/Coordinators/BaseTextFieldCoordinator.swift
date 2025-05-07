//
//  BaseTextFieldCoordinator.swift
//  Created by Boris on 29. 4. 2025..
//

import UIKit

/// Base coordinator that composes formatting, cursor, and validation
public class BaseTextFieldCoordinator: NSObject, UITextFieldDelegate, LogReporter {
    /// Now mutable so you can replace CardNumberFormatter when the BIN changes
    public var formatter: FieldFormatter

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
        super.init()
    }

    /// Call this whenever you detect a new CardNetwork
    public func update(cardNetwork: CardNetwork) {
        // Only swap for card‐number fields
        if formatter is CardNumberFormatter {
            formatter = CardNumberFormatter(cardNetwork: cardNetwork)
        }
    }

    // MARK: UITextFieldDelegate

    public func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let current = textField.text ?? ""
        guard let swiftRange = Range(range, in: current) else { return false }
        let updated = current.replacingCharacters(in: swiftRange, with: string)

        // Filter raw digits/letters according to the field type
        let raw: String
        if formatter is ExpiryDateFormatter {
            raw = updated.filter { $0.isNumber || $0 == "/" }
        } else if formatter is CVVFormatter {
            raw = updated.filter { $0.isNumber }
        } else if formatter is CardholderNameFormatter {
            // TODO: Add all possible special characters that could be found in a person's name?
            raw = updated.filter { $0.isLetter || $0.isWhitespace || $0 == "'" || $0 == "-" }
        } else {
            raw = updated.filter { $0.isNumber || $0.isLetter }
        }

        // Format and push back in
        let formatted = formatter.format(raw)
        textField.text = formatted
        onTextChange(formatted)

        // Compute and set new cursor position
        let originalOffset = range.location + string.count
        let newOffset = cursorManager.position(for: raw, formatted: formatted, original: originalOffset)
        if let pos = textField.position(from: textField.beginningOfDocument, offset: min(newOffset, formatted.count)) {
            textField.selectedTextRange = textField.textRange(from: pos, to: pos)
        }

        // Remember raw for blur validation
        lastRaw = raw

        // Live validation
        let result = validator.validateWhileTyping(raw)
        logger.debug(message: "While typing: '\(raw)' valid=\(result.isValid) err=\(result.errorMessage ?? "nil")")
        onValidationChange(result.isValid)
        onErrorMessageChange(result.errorMessage)

        return false
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        // Clear any old error
        onErrorMessageChange(nil)
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        // Final validation on blur
        let result = validator.validateOnCommit(lastRaw)
        onValidationChange(result.isValid)
        onErrorMessageChange(result.errorMessage)
    }
}
