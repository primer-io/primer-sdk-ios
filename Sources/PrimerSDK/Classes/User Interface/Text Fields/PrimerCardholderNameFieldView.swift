//
//  PrimerCardholderFieldView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 5/7/21.
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
        editingAnalyticsObjectId = .cardHolder
        validationError = .invalidCardholderName(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
        isValid = { text in
            return text.isTypingNonDecimalCharacters
        }
    }
}

#endif
