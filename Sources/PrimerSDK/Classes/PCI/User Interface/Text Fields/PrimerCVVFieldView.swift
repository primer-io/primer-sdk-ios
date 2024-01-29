//
//  PrimerCVVFieldView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 5/7/21.
//

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

    public override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField.internalText ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        if !(newText.isNumeric || newText.isEmpty) { return false }
        if string != "" && newText.withoutWhiteSpace.count >= 5 { return false }

        switch self.isValid?(newText) {
        case true:
            validation = .valid
        case false:
            if newText.isEmpty {
                let err = PrimerValidationError.invalidCvv(
                    message: "CVV cannot be blank.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                validation = .invalid(err)

            } else {
                let err = PrimerValidationError.invalidCvv(
                    message: "CVV is not valid.",
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

        default:
            validation = .notAvailable
        }

        primerTextField.internalText = newText
        primerTextField.text = newText

        switch validation {
        case .valid:
            if let cvvLength = cardNetwork.validation?.code.length, newText.count == cvvLength {
                delegate?.primerTextFieldView(self, isValid: true)
            } else {
                delegate?.primerTextFieldView(self, isValid: nil)
            }
        case .invalid:
            if let cvvLength = cardNetwork.validation?.code.length, newText.count == cvvLength {
                delegate?.primerTextFieldView(self, isValid: false)
            } else {
                delegate?.primerTextFieldView(self, isValid: nil)
            }
        default:
            delegate?.primerTextFieldView(self, isValid: nil)
        }

        return false
    }

}
