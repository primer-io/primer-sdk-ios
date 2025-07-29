//
//  PrimerPostalCodeFieldView.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

public final class PrimerPostalCodeFieldView: PrimerTextFieldView {

    internal var postalCode: String? {
        return textField.internalText
    }

    override func xibSetup() {
        super.xibSetup()
        keyboardType = .namePhonePad
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "postal_code_txt_fld"
        textField.delegate = self
        isEditingAnalyticsEnabled = true
        isValid = { text in
            // todo: look into more sophisticated postal code validation, ascii check for now
            return text.isValidPostalCode
        }
    }

    public override func textFieldDidBeginEditing(_ textField: UITextField) {
        super.textFieldDidBeginEditing(textField)
        let event = cardFormFieldDidBeginEditingEventWithObjectId(.billingAddressPostalCode)
        sendTextFieldDidEndEditingAnalyticsEventIfNeeded(event)
    }

    public override func textFieldDidEndEditing(_ textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        let event = cardFormFieldDidEndEditingEventWithObjectId(.billingAddressPostalCode)
        sendTextFieldDidEndEditingAnalyticsEventIfNeeded(event)
    }

    // todo: refactor into separate functions somewhere
    public override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let positionOriginal = textField.beginningOfDocument
        let cursorLocation = textField.position(
            from: positionOriginal,
            offset: (range.location + NSString(string: string).length)
        )

        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField.internalText ?? ""

        // Ensure range is within bounds
        guard range.location <= currentText.count, range.length <= currentText.count - range.location else {
            return false
        }

        let newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String

        switch self.isValid?(newText) {
        case true:
            validation = .valid
        case false:
            validation = .invalid(handled(primerValidationError: .invalidPostalCode(message: "Postal code is not valid.")))
        default:
            validation = .notAvailable
        }

        switch validation {
        case .valid:
            delegate?.primerTextFieldView(self, isValid: true)
        default:
            delegate?.primerTextFieldView(self, isValid: nil)
        }

        primerTextField.internalText = newText
        primerTextField.text = newText

        if let cursorLoc = cursorLocation {
            textField.selectedTextRange = textField.textRange(from: cursorLoc, to: cursorLoc)
        }

        return false
    }

}
