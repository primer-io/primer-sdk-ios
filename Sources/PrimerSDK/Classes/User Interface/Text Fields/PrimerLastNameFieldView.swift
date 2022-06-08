#if canImport(UIKit)

import UIKit

public final class PrimerLastNameFieldView: PrimerSimpleCardFormTextFieldView {
    
    internal var lastName: String {
        return textField._text ?? ""
    }
    
    override func xibSetup() {
        super.xibSetup()
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "last_name_txt_fld"
        isEditingAnalyticsEnabled = true
        editingAnalyticsObjectId = .billingAddressLastName
        validationError = .invalidCardholderName(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
        isValid = { text in
            return text.isTypingNonDecimalCharacters
        }
    }
}

#endif
