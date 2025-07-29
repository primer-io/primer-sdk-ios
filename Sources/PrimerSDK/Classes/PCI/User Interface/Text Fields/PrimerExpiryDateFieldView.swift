//
//  PrimerExpiryDateFieldView.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length

import UIKit

public final class PrimerExpiryDateFieldView: PrimerTextFieldView {

    internal(set) public var expiryMonth: String?
    internal(set) public var expiryYear: String?

    override func xibSetup() {
        super.xibSetup()
        keyboardType = .numberPad
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "expiry_txt_fld"
        textField.delegate = self
        isEditingAnalyticsEnabled = true
        editingAnalyticsObjectId = .expiry
        isValid = { text in
            let isValid = text.isValidExpiryDate
            return isValid
        }
    }

    public override func textField(_ textField: UITextField,
                                   shouldChangeCharactersIn range: NSRange,
                                   replacementString string: String) -> Bool {
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField.internalText ?? ""

        // Ensure range is within bounds
        guard range.location <= currentText.count, range.length <= currentText.count - range.location else {
            return false
        }

        var newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        newText = newText.replacingOccurrences(of: "/", with: "")
        if !(newText.isNumeric || newText.isEmpty) { return false }
        if string != "" && newText.withoutWhiteSpace.count >= 5 { return false }

        if self.isValid?(newText) ?? false {
            validation = .valid
        } else {
            let message = """
Expiry date is not valid. Valid expiry date format is 2 characters for \
expiry month and 4 characters for expiry year separated by '/'.
"""
            validation = .invalid(PrimerValidationError.invalidExpiryDate(message: message))
        }

        if string != "" {   // Typing
            if newText.count == 2 {
                newText += "/"
            } else {
                newText = newText.separate(every: 2, with: "/")
            }

        } else {            // Deleting
            if newText.count == 2 {
                //            newText += "/"
            } else {
                newText = newText.separate(every: 2, with: "/")
            }
        }

        primerTextField.internalText = newText
        primerTextField.text = newText

        if newText.isValidExpiryDate {
            expiryMonth = String(newText.prefix(2))
            expiryYear = String(newText.suffix(2))
        } else {
            expiryMonth = nil
            expiryYear = nil
        }

        if newText.count == 5, !newText.isValidExpiryDate {
            delegate?.primerTextFieldView(self, isValid: false)
        } else {
            switch validation {
            case .valid:
                delegate?.primerTextFieldView(self, isValid: true)
            default:
                delegate?.primerTextFieldView(self, isValid: nil)
            }
        }
        return false
    }
}
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
