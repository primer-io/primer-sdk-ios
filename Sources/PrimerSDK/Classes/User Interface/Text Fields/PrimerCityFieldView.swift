#if canImport(UIKit)

import UIKit

public final class PrimerCityFieldView: PrimerSimpleCardFormTextFieldView {
    
    internal var city: String {
        return textField._text ?? ""
    }
    
    override func xibSetup() {
        super.xibSetup()
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "city_txt_fld"
        isEditingAnalyticsEnabled = true
        editingAnalyticsObjectId = .billingAddressCity
        validationError = .invalidState(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
        isValid = { text in
            return text.isTypingNonDecimalCharacters
        }
    }
}

#endif
