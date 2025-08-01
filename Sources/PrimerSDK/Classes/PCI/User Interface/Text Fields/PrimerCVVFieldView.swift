//
//  PrimerCVVFieldView.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length

import UIKit

public final class PrimerCVVFieldView: PrimerTextFieldView {

    internal var cvv: String {
        return textField.internalText ?? ""
    }
    public var cardNetwork: CardNetwork = .unknown

    override func xibSetup() {
        super.xibSetup()
        keyboardType = .numberPad
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "cvc_txt_fld"
        textField.delegate = self
        isEditingAnalyticsEnabled = true
        editingAnalyticsObjectId = .cvc
        isValid = { [weak self] text in
            guard let strongSelf = self else { return false }
            return text.isTypingValidCVV(cardNetwork: strongSelf.cardNetwork)
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

        let newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        if !(newText.isNumeric || newText.isEmpty) { return false }
        if string != "" && newText.withoutWhiteSpace.count >= 5 { return false }

        switch self.isValid?(newText) {
        case true:
            validation = .valid
        case false:
            if newText.isEmpty {
                validation = .invalid(PrimerValidationError.invalidCvv(message: "CVV cannot be blank."))
            } else {
                validation = .invalid(PrimerValidationError.invalidCvv(message: "CVV is not valid."))
            }

        default:
            validation = .notAvailable
        }

        primerTextField.internalText = newText
        primerTextField.text = newText

        let isValidCVVLength: Bool?
        if let cvvLength = cardNetwork.validation?.code.length {
            isValidCVVLength = newText.count == cvvLength
        } else {
            isValidCVVLength = nil
        }

        switch validation {
        case .valid, .invalid:
            delegate?.primerTextFieldView(self, isValid: isValidCVVLength)
        default:
            delegate?.primerTextFieldView(self, isValid: nil)
        }

        return false
    }
}
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
