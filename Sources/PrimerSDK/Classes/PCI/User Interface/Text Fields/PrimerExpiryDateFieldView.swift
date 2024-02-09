//
//  PrimerExpiryDateFieldView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 5/7/21.
//

import UIKit

public final class PrimerExpiryDateFieldView: PrimerTextFieldView {

    private(set) public var expiryMonth: String?
    private(set) public var expiryYear: String?

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

    public override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField.internalText ?? ""
        var newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        newText = newText.replacingOccurrences(of: "/", with: "")
        if !(newText.isNumeric || newText.isEmpty) { return false }
        if string != "" && newText.withoutWhiteSpace.count >= 5 { return false }

        if self.isValid?(newText) ?? false {
            validation = .valid
        } else {
            let err = PrimerValidationError.invalidExpiryDate(
                message: "Expiry date is not valid. Valid expiry date format is 2 characters for expiry month and 4 characters for expiry year separated by '/'.",
                userInfo: [
                    "file": #file,
                    "class": "\(Self.self)",
                    "function": #function,
                    "line": "\(#line)"
                ],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            validation = .invalid(err)
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
