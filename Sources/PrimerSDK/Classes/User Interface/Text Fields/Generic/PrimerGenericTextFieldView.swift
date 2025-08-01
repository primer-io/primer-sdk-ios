//
//  PrimerGenericTextFieldView.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

public final class PrimerGenericFieldView: PrimerTextFieldView {

    public var allowedCharacterSet: CharacterSet?
    public var maxCharactersAllowed: UInt?
    public var shouldMaskText: Bool = false
    public override var text: String? {
        get {
            return shouldMaskText ? "****" : textField.internalText
        }
        set {
            textField.internalText = newValue
        }
    }

    override func xibSetup() {
        super.xibSetup()
        keyboardType = .namePhonePad
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "generic_txt_fld"
        textField.delegate = self
    }

    public override func textField(_ textField: UITextField,
                                   shouldChangeCharactersIn range: NSRange,
                                   replacementString string: String) -> Bool {

        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField.internalText ?? ""

        if maxCharactersAllowed != nil && !string.isEmpty && currentText.count >= maxCharactersAllowed! {
            return false
        }

        // Ensure range is within bounds
        guard range.location <= currentText.count, range.length <= currentText.count - range.location else {
            return false
        }

        let newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String

        if let allowedCharacterSet = allowedCharacterSet {
            if !string.isEmpty && newText.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil {
                return false
            }
        }

        primerTextField.internalText = newText

        let valid = PrimerTextField.Validation.valid

        let invalid = PrimerTextField.Validation.invalid(PrimerValidationError.invalidCardnumber(message: "Card number is not valid."))
        validation = (self.isValid?(primerTextField.internalText?.withoutWhiteSpace ?? "") ?? false) ? valid : invalid

        switch validation {
        case .valid:
            delegate?.primerTextFieldView(self, isValid: true)
        default:
            delegate?.primerTextFieldView(self, isValid: nil)
        }

        return true
    }

}
