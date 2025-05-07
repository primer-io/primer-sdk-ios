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
    private var isUpdating: Bool = false

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
        // Only swap for card‐number or CVV fields
        if formatter is CardNumberFormatter {
            formatter = CardNumberFormatter(cardNetwork: cardNetwork)
            // Re-format the current text with the new formatter
            if let textField = currentTextField, let text = textField.text {
                let raw = text.filter { $0.isNumber }
                let formatted = formatter.format(raw)
                if formatted != text {
                    textField.text = formatted
                    onTextChange(formatted)
                }
            }
        } else if formatter is CVVFormatter {
            formatter = CVVFormatter(cardNetwork: cardNetwork)
            // Re-format CVV with new card network
            if let textField = currentTextField, let text = textField.text {
                let raw = text.filter { $0.isNumber }
                let formatted = formatter.format(raw)
                if formatted != text {
                    textField.text = formatted
                    onTextChange(formatted)
                }
            }
        }
    }

    // Keep track of the current text field
    private weak var currentTextField: UITextField?

    // MARK: UITextFieldDelegate

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        currentTextField = textField
        // Clear any old error
        onErrorMessageChange(nil)
    }

    public func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        // Avoid reentrance
        if isUpdating {
            return false
        }

        isUpdating = true
        defer { isUpdating = false }

        let current = textField.text ?? ""
        guard let swiftRange = Range(range, in: current) else { return false }
        let updated = current.replacingCharacters(in: swiftRange, with: string)

        // Filter raw input according to field type
        let raw: String
        if formatter is ExpiryDateFormatter {
            raw = updated.filter { $0.isNumber || $0 == "/" }
        } else if formatter is CVVFormatter {
            raw = updated.filter { $0.isNumber }
        } else if formatter is CardholderNameFormatter {
            raw = updated.filter { $0.isLetter || $0.isWhitespace || $0 == "'" || $0 == "-" }
        } else {
            raw = updated.filter { $0.isNumber || $0.isLetter }
        }

        // Format the raw input
        let formatted = formatter.format(raw)

        // Check if we're actually changing something
        if formatted == current {
            return false
        }

        // Update the text field
        textField.text = formatted
        onTextChange(formatted)

        // Compute and set new cursor position
        let originalOffset = range.location + string.count
        let newOffset = cursorManager.position(for: raw, formatted: formatted, original: originalOffset)
        if let pos = textField.position(from: textField.beginningOfDocument, offset: min(newOffset, formatted.count)) {
            textField.selectedTextRange = textField.textRange(from: pos, to: pos)
        }

        // Remember formatted text for blur validation
        lastRaw = formatted

        // Live validation with formatted text
        let result = validator.validateWhileTyping(formatted)
        logger.debug(message: "While typing: '\(formatted)' valid=\(result.isValid) err=\(result.errorMessage ?? "nil")")
        onValidationChange(result.isValid)
        onErrorMessageChange(result.errorMessage)

        return false
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        // Final validation on blur
        let result = validator.validateOnCommit(lastRaw)
        onValidationChange(result.isValid)
        onErrorMessageChange(result.errorMessage)
        currentTextField = nil
    }
}
