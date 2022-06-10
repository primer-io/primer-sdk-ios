#if canImport(UIKit)

import UIKit

public final class PrimerFirstNameFieldView: PrimerSimpleCardFormTextFieldView {
    
    internal var firstName: String? {
        return textField._text
    }
    
    override func xibSetup() {
        super.xibSetup()
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "first_name_txt_fld"
        isEditingAnalyticsEnabled = true
        editingAnalyticsObjectId = .billingAddressFirstName
        validationError = .invalidFirstName(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
        isValid = { text in
            return text.isTypingNonDecimalCharacters
        }
    }
}

#endif
