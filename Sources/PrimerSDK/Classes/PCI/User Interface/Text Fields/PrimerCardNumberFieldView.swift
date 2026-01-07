//
//  PrimerCardNumberFieldView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length

import UIKit
import PrimerFoundation

public final class PrimerCardNumberFieldView: PrimerTextFieldView {

    public private(set) var cardNetwork: CardNetwork = .unknown
    var cardnumber: String {
        (textField.internalText ?? "").replacingOccurrences(of: " ", with: "").withoutWhiteSpace
    }

    override func xibSetup() {
        super.xibSetup()
        keyboardType = .numberPad
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "card_txt_fld"
        textField.delegate = self
        isEditingAnalyticsEnabled = true
        editingAnalyticsObjectId = .cardNumber
        isValid = { text in
            text.isValidCardNumber
        }
    }

    override public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField.internalText ?? ""
        if string != "", currentText.withoutWhiteSpace.count == 19 { return false }

        // Ensure range is within bounds
        guard range.location <= currentText.count, range.length <= currentText.count - range.location else {
            return false
        }

        let newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        if !newText.withoutWhiteSpace.isNumeric, !string.isEmpty { return false }
        primerTextField.internalText = newText

        DispatchQueue.global(qos: .userInitiated).async {
            self.cardNetwork = CardNetwork(cardNumber: primerTextField.internalText ?? "")

            DispatchQueue.main.async {
                if newText.isEmpty {
                    self.delegate?.primerTextFieldView(self, didDetectCardNetwork: nil)
                } else {
                    self.delegate?.primerTextFieldView(self, didDetectCardNetwork: self.cardNetwork)
                }
            }

            if self.isValid?(primerTextField.internalText?.withoutWhiteSpace ?? "") ?? false {
                self.validation = .valid
            } else if (primerTextField.internalText?.withoutWhiteSpace ?? "").isEmpty {
                let err = PrimerValidationError.invalidCardnumber(message: "Card number can not be blank.")
                self.validation = PrimerTextField.Validation.invalid(err)

            } else {
                let err = PrimerValidationError.invalidCardnumber(message: "Card number is not valid.")
                self.validation = PrimerTextField.Validation.invalid(err)
            }

            DispatchQueue.main.async {
                switch self.validation {
                case .valid:
                    if let maxLength = self.cardNetwork.validation?.lengths.max(), newText.withoutWhiteSpace.count == maxLength {
                        self.delegate?.primerTextFieldView(self, isValid: true)
                    } else {
                        self.delegate?.primerTextFieldView(self, isValid: nil)
                    }
                case .invalid:
                    if let maxLength = self.cardNetwork.validation?.lengths.max(), newText.withoutWhiteSpace.count == maxLength {
                        self.delegate?.primerTextFieldView(self, isValid: false)
                    } else {
                        self.delegate?.primerTextFieldView(self, isValid: nil)
                    }
                default:
                    self.delegate?.primerTextFieldView(self, isValid: nil)
                }
            }
        }

        primerTextField.text = newText.withoutWhiteSpace.separate(every: 4, with: " ")

        // Detect pasting of the card number
        if string.count > 1, (primerTextField.internalText?.count ?? 0) > 1 {
            if let text = primerTextField.internalText {

                // Get the position of the last character in the string
                if let endPosition = primerTextField.position(from: primerTextField.beginningOfDocument, offset: text.count) {
                    DispatchQueue.main.async {
                        // Create a UITextRange from the endPosition to endPosition (for placing the cursor at the end)
                        primerTextField.selectedTextRange = primerTextField.textRange(from: endPosition, to: endPosition)
                    }
                }
            }
        }

        return false
    }
}
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
