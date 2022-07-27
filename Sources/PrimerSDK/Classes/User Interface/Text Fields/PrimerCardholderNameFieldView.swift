//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

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
        validationError = .invalidCardholderName(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
        isValid = { text in
            return text.isTypingNonDecimalCharacters
        }
    }
    
    public override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard string.isTypingNonDecimalCharacters == true || string.isEmpty else { return false }
        return super.textField(textField, shouldChangeCharactersIn: range, replacementString: string)
    }
}

#endif
