//
//  PrimerExpiryDateFieldView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable function_body_length

@_spi(PrimerInternal) import PrimerFoundation
import UIKit
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerUI

public final class PrimerExpiryDateFieldView: PrimerTextFieldView {

    public internal(set) var expiryMonth: String?
    public internal(set) var expiryYear: String?

    override public func xibSetup() {
        super.xibSetup()
        keyboardType = .numberPad
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "expiry_txt_fld"
        if #available(iOS 17, *) { textContentType = .creditCardExpiration }
        textField.delegate = self
        isEditingAnalyticsEnabled = true
        editingAnalyticsObjectId = .expiry
        isValid = { text in
            let isValid = text.isValidExpiryDate
            return isValid
        }
    }

    override public func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField.internalText ?? ""

        // Ensure range is within bounds
        guard range.location <= currentText.count, range.length <= currentText.count - range.location else {
            return false
        }

        let string = string.count > 1 ? Self.expiryDigits(from: string) : string
        var newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        newText = newText.replacingOccurrences(of: "/", with: "")
        if !(newText.isNumeric || newText.isEmpty) || (string != "" && newText.withoutWhiteSpace.count >= 5) {
            return false
        }

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

        expiryMonth = newText.isValidExpiryDate ? String(newText.prefix(2)) : nil
        expiryYear =  newText.isValidExpiryDate ? String(newText.suffix(2)) : nil

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

    /// AutoFill and card scan insert the whole date, sometimes as M/YY, MM/YYYY or MMYYYY.
    private static func expiryDigits(from date: String) -> String {
        let parts = date.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
        switch parts.count {
        case 1 where parts[0].count == 6:
            return String(parts[0].prefix(2) + parts[0].suffix(2))
        case 2 where (1 ... 2).contains(parts[0].count) && [2, 4].contains(parts[1].count):
            return String(repeating: "0", count: 2 - parts[0].count) + parts[0] + parts[1].suffix(2)
        default:
            return date
        }
    }
}
// swiftlint:enable function_body_length
