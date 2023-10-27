//
//  PrimerCardholderFieldView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 5/7/21.
//



import UIKit

public final class PrimerCardholderNameFieldView: PrimerSimpleCardFormTextFieldView {
    
    internal var cardholderName: String {
        return textField._text ?? ""
    }
    
    override func xibSetup() {
        super.xibSetup()
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "card_holder_txt_fld"
        isEditingAnalyticsEnabled = true
        textField.delegate = self
        editingAnalyticsObjectId = .cardHolder
        validationError = .invalidCardholderName(
            message: "Cardholder name is not valid.",
            userInfo: [
                "file": #file,
                "class": "\(Self.self)",
                "function": #function,
                "line": "\(#line)"
            ],
            diagnosticsId: UUID().uuidString)
        isValid = { text in
            return text.isValidNonDecimalString
        }
    }
    
    public override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard string.isValidNonDecimalString == true || string.isEmpty else { return false }
        return super.textField(textField, shouldChangeCharactersIn: range, replacementString: string)
    }
}


